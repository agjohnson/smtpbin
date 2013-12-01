package SMTPbin::Util;

use 5.010;
use strict;
use warnings;

use JSON qw//;
use Config::Any;

use Exporter 'import';
our @EXPORT = qw/
    jsonify
    decode_body
    config
/;

our %Config;

# Serialization
sub jsonify {
    my ($obj) = @_;
    return JSON->new
      ->allow_nonref->allow_blessed->convert_blessed
      ->encode($obj);
}

sub decode_body {
    my $req = shift;
    if ($req->content_type == 'application/json') {
        return JSON->new
          ->allow_nonref
          ->decode($req->content);
    }
    return {};
}

# Config file
sub config {
    return \%Config
      if (%Config);
    my $cfger = _load_config();
    %Config = map { %{$cfger->{$_}} } keys %{$cfger};
    return \%Config;
}

sub _load_config {
    return Config::Any->load_stems({
        stems => [qw/config/],
        use_ext => 1,
        flatten_to_hash => 1
    });
}

1;
