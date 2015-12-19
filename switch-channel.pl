#!/usr/bin/perl

use HTTP::Request;
use LWP::UserAgent;
use JSON;

my $TV_IP = 'fernseher';
#my $TV_IP = '192.168.178.20';
my $channels_file = '/tmp/.channels';

my $channel = join ' ', @ARGV;
my $channels_json = '';

unless ( -r $channels_file ) {
    $channels_json = tv_request('channels');
    open CHANNEL_LIST, ">$channels_file";
    print CHANNEL_LIST $channels_json;
    close CHANNEL_LIST;
} else {
    open CHANNEL_LIST, $channels_file or die;
    $channels_json .= $_ while <CHANNEL_LIST>;
    close CHANNEL_LIST;
}

my $channel_list = from_json($channels_json, { utf8 => 0 });
foreach my $id ( sort { $channel_list->{$a}{'preset'} <=> $channel_list->{$b}{'preset'} } grep { /^0-/ } keys %$channel_list ) {
    next unless $channel_list->{$id}{'name'} =~ m|$channel|i;

    print "Switch to: $channel_list->{$id}{'name'} (channel: $channel_list->{$id}{'preset'})\n";
    tv_request('channels/current', {'id' => $id});
    last;
}

sub tv_request {
    my ($service, $data) = @_;
    my $type = $data ? 'POST' : 'GET';

    my $request = HTTP::Request->new($type => "http://$TV_IP:1925/1/$service");
    if ( $type eq 'POST' ) {
	$request->content_type('application/json');
	$request->content(encode_json($data));
    }
    my $ua = LWP::UserAgent->new();
    my $response = $ua->request($request);
    die $response->status_line() unless $response->is_success();
    return $response->content();
}
