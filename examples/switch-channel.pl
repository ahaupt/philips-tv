#!/usr/bin/perl

use lib "../lib";
use TV::Philips;

my $TV_IP = 'fernseher';

my $tv = TV::Philips->new($TV_IP);
$tv->channel(shift());
