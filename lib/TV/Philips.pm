package TV::Philips;

use strict;
use warnings;

use Carp qw(croak);

use HTTP::Request;
use LWP::UserAgent;
use JSON;

our $VERSION = '0.01';

###

sub new {
    my $class = shift();
    my $self = {
	'tv_address' => shift()
    };
    bless $self, $class;
}

sub data {
    my $this = shift();
    return $this->_request('system');
}

sub volume {
    my ($this, $set_vol) = @_;
    my $data = $this->_request('audio/volume');
    return $data->{'current'} unless defined $set_vol;

    my $new_volume = 0;
    $new_volume = $set_vol if $set_vol =~ m|^(\d+)$|;
    $new_volume = $data->{'current'}+$set_vol if $set_vol =~ m|^[+-](\d+)$|;
    return $this->_request('audio/volume',
	{ 'muted' => 'false', 'current' => $new_volume });
}

sub muted {
    my $this = shift();
    my $data = $this->_request('audio/volume');
    return $data->{'muted'};
}

sub mute {
    my $this = shift();
    return $this->_request('input/key', {'key' => 'Mute'})
	unless $this->muted();
}

sub unmute {
    my $this = shift();
    return $this->_request('input/key', {'key' => 'Mute'})
	if $this->muted();
}

sub channel {
    my ($this, $preset, $list) = @_;
    $this->_init_channels() unless defined $this->{'raw-channels'};
    if ( $preset ) {
	$list = 0 unless defined $list;
	my $id = 0;
	while ( ($id, my $data) = each %{$this->{'raw-channels'}} ) {
	    last if $preset eq $data->{'preset'} && $id =~ /^$list-/;
	}
	return $this->_request('channels/current', {'id' => $id});
    }
    my $data = $this->_request('channels/current');
    return $this->{'raw-channels'}{$data->{'id'}}{'preset'};
}

sub channel_name {
    my ($this, $preset, $list) = @_;
    $list = 0 unless defined $list;
    $this->_init_channels() unless defined $this->{'raw-channels'};

    return $this->{'channels'}{$list}{$preset};
}

sub channels {
    my ($this, $list) = @_;
    $list = 0 unless defined $list;
    $this->_init_channels() unless defined $this->{'raw-channels'};

    return $this->{'channels'}{$list};
}

sub source {
    my ($this, $new_source) = @_;
    return $this->_request('sources/current')->{'id'};
}

sub source_name {
    my ($this, $source) = @_;
    my $data = $this->_request('sources');
    return $data->{$source}{'name'};
}

sub sources {
    my $this = shift();
    return $this->_request('sources');
}

sub ambilight {
    my $this = shift();
    my $data = $this->_request('ambilight/topology');
    return {
	'left'	=> $data->{'left'} > 0 || 0,
	'right'	=> $data->{'right'} > 0 || 0,
	'top'	=> $data->{'top'} > 0 || 0,
	'bottom'=> $data->{'bottom'} > 0 || 0
    };
}

sub switchoff {
    my $this = shift();
    return $this->_request('input/key', {'key' => 'Standby'});
}

sub _init_channels {
    my $this = shift;
    $this->{'raw-channels'} = $this->_request('channels');

    foreach my $id ( keys %{$this->{'raw-channels'}} ) {
	$id =~ /^(\d)-/;
	$this->{'channels'}{$1}{$this->{'raw-channels'}{$id}{'preset'}} = $this->{'raw-channels'}{$id}{'name'};
    }
}

sub _request {
    my ($this, $service, $data) = @_;
    my $type = $data ? 'POST' : 'GET';

    my $request = HTTP::Request->new($type => "http://$this->{'tv_address'}:1925/1/$service");
    if ( $type eq 'POST' ) {
	$request->content_type('application/json');
	$request->content(encode_json($data));
    }
    my $ua = LWP::UserAgent->new();
    my $response = $ua->request($request);
    croak $response->status_line() unless $response->is_success();

    return $type eq 'POST' ? 
	$response->is_success() :
	from_json($response->content(), { utf8 => 1 });
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

TV::Philips - Perl extension for interacting with Philips Smart-TV

=head1 SYNOPSIS

  use TV::Philips;
  
  $tv = TV::Philips->new('name_or_ip_of_tv');
  $tvdata = $tv->data();

=head1 DESCRIPTION

Interact with Philips Smart-TV

=head1 METHODS

$data = $tv->data()
  Returns a hash containing general data about the tv.

=head1 AUTHOR

Andreas Haupt, E<lt>mail@andreas-haupt.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Andreas Haupt

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
