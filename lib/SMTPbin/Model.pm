package SMTPbin::Model;

use 5.010;
use strict;
use warnings;

use Mouse;
use AnyEvent;
use AnyEvent::Redis;
use JSON qw//;


my $DB;

sub connect {
    my $class = shift;
    $SMTPbin::Model::DB = AnyEvent::Redis->new(
        on_error => sub { warn "Error: @_" },
        on_cleanup => sub { warn "Connection: @_" },
        @_
    );
}

sub db {
    my $self = shift;
    return $SMTPbin::Model::DB;
}

# Override functions
sub db_key {
    return sprintf('null');
}

# Serialization
sub json_attr {
    my ($self, $attr, $value) = @_;
    if (defined $value) {
        return $self->{$attr} = JSON->new
          ->allow_nonref->decode($value);
    }
    return JSON->new
      ->allow_nonref->allow_blessed->convert_blessed
      ->encode($self->{$attr});
}

1;
