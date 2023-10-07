package CyUtils;
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use JSON;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use MIME::Base64 qw(encode_base64);
use CGI qw(:standard);
use File::Basename;
use Data::Dumper;
use MIME::Types;
no warnings;

my $server_address = '';
my $user_agent = "Cyberno-API-Sample-Perl";

sub new {
    my ($class, $server_address) = @_;
    my $self = {
        server_address => $server_address,
    };
    return bless $self, $class;
}

sub get_sha256 {
    my ($file_path) = @_;
    my $hash_sha256;
    open my $fh, "<", $file_path or return { success => 0, error_code => 900 };
    $hash_sha256 = sha256_hex(scalar <$fh>);
    close $fh;
    return $hash_sha256;
}

sub get_error {
    my ($return_value) = @_;
    my $error = 'Error!\n';
    if (exists $return_value->{error_code}) {
        $error .= ("Error code: $return_value->{error_code}\n");
    }
    if (exists $return_value->{error_desc}) {
        $error .= ("Error description: $return_value->{error_desc}\n");
    }
    return $error;
}

sub call_with_json_input {
    my ($self, $api, $json_input) = @_;
    my $ua = LWP::UserAgent->new;
    $ua->agent($user_agent);
    my $request = POST($self->{server_address} . $api, Content_Type => 'application/json', Content => encode_json($json_input));
    my $response = $ua->request($request);
    if ($response->is_success) {
        my $data = $response->decoded_content;
        my $values = decode_json($data);
        return $values;
    }
    else {
        my $values = { success => 0, error_code => 900 };
        if ($response->content) {
            my $data = $response->decoded_content;
            $values = decode_json($data);
        }
        return $values;
    }
}

sub call_with_form_input {
    my ($self, $api, $data_input, $file_param_name, $file_path) = @_;
    my $url = $self->{server_address} . $api;
    my $ua = LWP::UserAgent->new;
    $ua->agent($user_agent);
    my $form_data = {};
    foreach my $key (keys %{$data_input}) {
        $form_data->{$key} = $data_input->{$key};
    }
    my $response = $ua->post($url, Content_Type => 'multipart/form-data', Content => [
        $file_param_name => [ $file_path ],
        %{$form_data}
    ]);
    my $result = decode_json($response->content);
    return $result;

}
