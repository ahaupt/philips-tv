#!/usr/bin/perl

use lib "../lib";
use TV::Philips;

use Dumpvalue;
my $d = new Dumpvalue();

my $TV_IP = shift();

my $tv = TV::Philips->new($TV_IP);

my $tv_data  = $tv->data();
my $ambilight= $tv->ambilight();
my $audio    = $tv->volume();
my $muted    = ($tv->muted() ? '' : 'not ') . 'muted';
my $csource  = $tv->source();
my $sources  = $tv->sources();
my $cchannel = $tv->current_channel();
$d->dumpValue($cchannel);
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
Current source:		$sources->{$csource->{'id'}}{'name'}
Current channel:	$channels->{$cchannel->{'id'}}{'name'} (preset: $channels->{$cchannel->{'id'}}{'preset'})
Current audio level:	$audio ($muted)
--------------------------------------------------------------------------------
-------------------------------- CHANNEL LIST ----------------------------------
EOF

my $i = 0;
foreach my $id ( sort { $channels->{$a}{'preset'} <=> $channels->{$b}{'preset'} } grep { /^0-/ } keys %$channels ) {
    printf("%4d: %-20.20s", $channels->{$id}{'preset'}, $channels->{$id}{'name'});
   print "\n" unless ++$i % 3;
}
print "\n";
