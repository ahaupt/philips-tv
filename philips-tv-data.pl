#!/usr/bin/perl

use HTTP::Request;
use LWP::UserAgent;
use JSON;

#use encoding ':locale';

my $TV_IP = shift();

my $tv_data  = tv_request('system');
my $ambilight= tv_request('ambilight/topology');
my $audio    = tv_request('audio/volume');
my $csource  = tv_request('sources/current');
my $sources  = tv_request('sources');
my $cchannel = tv_request('channels/current');
my $channels = tv_request('channels');

my $ambi = join ',', grep { $ambilight->{$_} } qw(left right top buttom);
my $muted = ($audio->{'muted'} ? '' : 'not ') . 'muted';

print<<"EOF";
$0 - show Philips TV data
--------------------------------------------------------------------------------
Name:			$tv_data->{'name'}
Model:			$tv_data->{'model'}
Serial Number:		$tv_data->{'serialnumber'}
Software Version:	$tv_data->{'softwareversion'}
Country:		$tv_data->{'country'}
Menu language:		$tv_data->{'menulanguage'}
Ambilight:		$ambi
--------------------------------------------------------------------------------
Current source:		$sources->{$csource->{'id'}}{'name'}
Current channel:	$channels->{$cchannel->{'id'}}{'name'} (preset: $channels->{$cchannel->{'id'}}{'preset'})
Current audio level:	$audio->{'current'} ($muted)
--------------------------------------------------------------------------------
-------------------------------- CHANNEL LIST ----------------------------------
EOF

my $i = 0;
foreach my $id ( sort { $channels->{$a}{'preset'} <=> $channels->{$b}{'preset'} } grep { /^0-/ } keys %$channels ) {
    printf("%4d: %-20.20s", $channels->{$id}{'preset'}, $channels->{$id}{'name'});
   print "\n" unless ++$i % 3;
}
print "\n";

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
    return $data ? 0 : from_json($response->content());
}
