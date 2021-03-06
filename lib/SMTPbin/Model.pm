package SMTPbin::Model;

use 5.010;
use strict;
use warnings;

use Mouse;
use AnyEvent;
use AnyEvent::Redis;
use JSON qw//;

use SMTPbin::Backend qw/logger/;
use Exporter 'import';
our @EXPORT = qw/
    db json_attr connect
/;

our $DB;

sub connect {
    my $class = shift;
    logger(info => 'Connecting to Redis');
    $SMTPbin::Model::DB = AnyEvent::Redis->new(
        on_error => sub { logger(error => "Error on connection to Redis: @_") },
        on_cleanup => sub { logger(info => "Connection cleanup to Redis: @_") },
        @_
    );
}

sub db {
    my $self = shift;
    my $_db = $SMTPbin::Model::DB;
    $self->connect if (!defined $_db);
    return $_db;
}

# Override functions
sub db_key {
    return sprintf('null');
}

# Serialization
sub json_attr {
    my ($self, $attr, $value) = @_;
    if (defined $value) {
        my $json = JSON->new
          ->allow_nonref
          ->decode($value);
        $self->{$attr} = $json
          if (ref $self eq 'HASH');
        return $json;
    }
    return JSON->new
      ->allow_nonref->allow_blessed->convert_blessed
      ->encode($self->{$attr});
}

1;
