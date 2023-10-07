use warnings;
use LWP::UserAgent;
no warnings;
use Data::Dumper;
use JSON qw(decode_json encode_json);
use lib "lib";
use CyUtils;

sub clean {
    my $text = shift;
    $text =~ s/\n//g;
    $text =~ s/\r//g;
    return $text;
}
# Check response result
sub check_response_result {
    my ($response) = shift;
    if ($response->{success} == 'false') {
        print($response->{error_desc} . "\n");
        exit 0;
    }
    else {
        my $clear_cmd = $^O eq 'MSWin32' ? 'cls' : 'clear';
        system($clear_cmd);
    }

}

print
    "  ______ ____    ____ .______    _______ .______      .__   __.   ______
 /      |\\   \\  /   / |   _  \\  |   ____||   _  \\     |  \\ |  |  /  __  \\
|  ,----' \\   \\/   /  |  |_)  | |  |__   |  |_)  |    |   \\|  | |  |  |  |
|  |       \\_    _/   |   _  <  |   __|  |      /     |  . `  | |  |  |  |
|  `----.    |  |     |  |_)  | |  |____ |  |\\  \\----.|  |\\   | |  `--'  |
 \\______|    |__|     |______/  |_______|| _| `._____||__| \\__|  \\______/
";

# Get user input
print "Please insert API server address [Default=https://multiscannerdemo.cyberno.ir/]: ";
my $server_address = <STDIN>;
if (clean($server_address) eq '') {
    $server_address = "https://multiscannerdemo.cyberno.ir/";
};
my $cyutils = CyUtils->new(clean($server_address));
print("Please insert identifier (email): ");
my $username = <STDIN>;
print("Please insert your password: ");
my $password = <STDIN>;

# Log in
my $login_response = $cyutils->call_with_json_input('user/login', { email => clean($username), password => clean($password) });
check_response_result($login_response);
my $apikey = $login_response->{data};
# Select scan mode
print("Please select scan mode:\n1- Scan local folder\n2- Scan file\nEnter Number=");
my $index = <STDIN>;
my $scan_response = '';
if (clean($index) == '1') {
    # Initialize scan
    print("Please enter the paths of file to scan (with spaces): ");
    my $file_path = <STDIN>;
    $file_path =~ s/\\/\//g;
    $file_path =~ s/"//g;
    my @file_path = split(' ', $file_path);
    print("Enter the name of the selected antivirus (with spaces): ");
    my $avs = <STDIN>;
    my @avs = split(' ', $avs);
    $scan_response = $cyutils->call_with_json_input('scan/init', { "token" => $apikey, "avs" => [ @avs ], "paths" => [ @file_path ] });
    check_response_result($scan_response);

}
else {
    # Initialize scan
    print("Please enter the path of file to scan: ");
    my $file_path = <STDIN>;
    $file_path =~ s/\\/\//g;
    $file_path =~ s/"//g;
    print("Enter the name of the selected antivirus: ");
    my $avs = <STDIN>;
    # Get file hash
    $scan_response = $cyutils->call_with_form_input('scan/multiscanner/init', { "token" => $apikey, "avs" => clean($avs) }, "file", clean($file_path));
    check_response_result($scan_response);
}

my $guid = $scan_response->{guid};
# Check password in path address
if ($scan_response->{password_protected}) {
    foreach $item (@{$scan_response->{password_protected}}) {
        print(qq{Enter the Password file -> $item: });
        my $password = <STDIN>;
        my $url = 'scan/extract/' . $guid;
        $muutils->call_with_json_input($url, { token => $apikey, path => $item, password => $password });
    }

}
# Start scan
my $scan_start_response = $cyutils->call_with_json_input('scan/start/' . $guid, { token => $apikey });
check_response_result($scan_start_response);
# Wait for scan results
my $is_finished = 0;
while ($is_finished == 0) {
    print "Waiting for result...\n";
    my $url = 'scan/result/' . $guid;
    my $scan_result_response = $cyutils->call_with_json_input($url, { token => $apikey });
    if ($scan_result_response->{data}->{finished_at}) {
        $is_finished = 1;
        print(JSON->new->pretty->encode($scan_result_response));
    }
    sleep(5)
}
