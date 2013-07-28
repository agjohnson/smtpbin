package SMTPbin::Model::Stats;

use Mouse;
use AnyEvent;

extends 'SMTPbin::Model';
use SMTPbin::Backend qw/logger/;
use SMTPbin::Util qw/jsonify/;

# Attributes
has 'id' => (
    is => 'rw',
    required => 1
);

has 'data' => (
    is => 'rw'
);


# Class methods for instanciation
sub find {
    my $class = shift;
    my %args = @_;

    # Pull out args
    my $id = $args{id};
    my $cb = $args{cb};

    my $stats = $class->new(id => $id);
    my $rcv; $rcv = $class->db->hgetall($class->db_key($id), sub {
        my $ret = shift;
        undef $rcv;
        my $cv = AnyEvent->condvar;
        $cv->cb($cb);
        if (@{$ret}) {
            logger(debug => "Found stats on lookup: ${id}");
            my %data = @{$ret};
            $stats->data(\%data);
            $cv->send($stats);
        }
        else {
            logger(debug => "Found empty stats on lookup: ${id}");
            $cv->send($stats)
        }
    });
    return $rcv;
}

sub add {
    my ($self, $key, $value) = @_;
    my $cv = AnyEvent->condvar;
    $value = $value // 1;

    # Stats
    $cv->begin;
    $self->db->hincrby($self->db_key, $key, $value, sub {
        $cv->end;
    });

    return $cv;
}

sub db_key {
    my $self = shift;
    my $id = shift // $self->id // 'foobar';
    return sprintf('stats:%s', $id);
}

# JSON
sub TO_JSON {
    my $self = shift;
    return {
        id => $self->id,
        %{$self->data}
    };
}

1;
