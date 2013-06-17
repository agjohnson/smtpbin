package SMTPbin::Util;

use 5.010;
use strict;
use warnings;

use JSON qw//;

use Exporter 'import';
our @EXPORT = qw/
    jsonify
/;


# Serialization
sub jsonify {
    my ($obj) = @_;
    return JSON->new
      ->allow_nonref->allow_blessed->convert_blessed
      ->encode($obj);
}

1;
