package SMTPbin::Model::Bin;

use Mouse;
use AnyEvent;
use Data::UUID;

extends 'SMTPbin::Model';
use SMTPbin::Model::Message;
use SMTPbin::Model::Stats;
use SMTPbin::Backend qw/logger/;
use SMTPbin::Util qw/jsonify/;

# Attributes
has 'id' => (
    is => 'rw',
    required => 1
);

has 'messages' => (
    is => 'rw'
);


# Class methods for instanciation
sub random {
    my $class = shift;
    $class->new(id => lc(Data::UUID->new->create_str));
}

sub find {
    my ($class, $id, $cb) = @_;
    my $bin = $class->new(id => $id);
    my $rcv; $rcv = $class->db->smembers($class->db_key($id), sub {
        my $ret = shift;
        undef $rcv;
        my $cv = AnyEvent->condvar;
        $cv->cb($cb);
        if (@{$ret}) {
            logger(debug => "Found bin with messages on lookup: ${id}");
            for my $msg_id (@{$ret}) {
                $cv->begin(sub { $cv->send($bin) });
                SMTPbin::Model::Message->find($msg_id, sub {
                    my $msg = shift->recv;
                    push(@{$bin->{messages}}, $msg)
                      if (defined $msg);
                    $cv->end;
                });
            }
        }
        else {
            logger(debug => "Found empty bin on lookup: ${id}");
            $cv->send($bin)
        }
    });
    return $rcv;
}

sub add {
    my ($self, $msg) = @_;
    my $cv = AnyEvent->condvar;

    # Add message to db set
    $cv->begin;
    $self->db->multi;
    $self->db->sadd($self->db_key, $msg->id);
    $self->db->expire($self->db_key, 600);
    $self->db->exec(sub { $cv->end });

    # Stats
    my $stats = SMTPbin::Model::Stats->new(
        id => $self->db_key
    );
    $cv->begin;
    my $cv1 = $stats->add('recv', 1);
    $cv1->cb(sub { undef $cv1; $cv->end; });

    return $cv;
}

# Attributes
sub url {
    return sprintf('/bin/%s', shift->id);
}

sub db_key {
    my $self = shift;
    my $id = shift // $self->id // 'foobar';
    return sprintf('bin:%s', $id);
}

# JSON
sub TO_JSON {
    my $self = shift;
    return {
        id => $self->id,
        messages => (defined $self->messages) ?
          map { $_ } @{$self->messages} : undef
    };
}

1;
