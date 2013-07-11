package SMTPbin::Util;

use 5.010;
use strict;
use warnings;

use JSON qw//;
use Config::Any;

use Exporter 'import';
our @EXPORT = qw/
    jsonify
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
