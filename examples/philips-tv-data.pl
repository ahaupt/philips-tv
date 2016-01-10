#!/usr/bin/perl

use lib "../lib";
use TV::Philips;

my $TV_IP = shift();
my $tv = TV::Philips->new($TV_IP);

my $tv_data  = $tv->data();
my $ambilight= $tv->ambilight();
my $audio    = $tv->volume();
my $muted    = ($tv->muted() ? '' : 'not ') . 'muted';
my $source  = $tv->source_name($tv->source());
my $cchannel = $tv->channel();
my $cchannel_name = $tv->channel_name($cchannel);
my $channels = $tv->channels();

my $ambi = join ',', grep { $ambilight->{$_} } qw(left right top buttom);

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
Current source:		$source
Current channel:	$cchannel_name (preset: $cchannel)
Current audio level:	$audio ($muted)
--------------------------------------------------------------------------------
-------------------------------- CHANNEL LIST ----------------------------------
EOF

my $i = 0;
foreach my $preset ( sort { $a <=> $b } keys %$channels ) {
    printf("%4d: %-20.20s", $preset, $channels->{$preset});
    print "\n" unless ++$i % 3;
}
print "\n";
