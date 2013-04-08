package SMTPbin::Model::Bin;

use Mouse;
use AnyEvent;
use Data::UUID;

extends 'SMTPbin::Model';
use SMTPbin::Model::Message;

# Attributes
has 'id' => (
    is => 'rw'
);

has 'messages' => (
    is => 'rw'
);

# Class methods for instanciation
sub random {
    my $class = shift;
    $class->new($class, id => Data::UUID->new->create_str);
}

sub find {
    my ($class, $id, $cb) = @_;
    my $cv = AnyEvent->condvar(
        cb => $cb
    );
    my $self = $class->new(id => $id);
    $class->db->smembers($self->db_key($id), sub {
        my $ret = shift;
        if (@{$ret}) {
            for my $msg_id (@{$ret}) {
                $cv->begin(sub { $cv->send($self) });
                SMTPbin::Model::Message->find($msg_id, sub {
                    my $msg = shift->recv;
                    push(@{$self->{messages}}, $msg)
                      if (defined $msg);
                    $cv->end;
                });
            }
        }
    });
    return $cv;
}

sub add {
    my ($self, $msg) = @_;
    $self->db->multi;
    $self->db->sadd($self->db_key, $msg->id);
    $self->db->expire($self->db_key, 600);
    # TODO add stats
    return $self->db->exec;
}

# Attributes
sub url {
    return sprintf('/bin/%s', shift->id);
}

sub db_key {
    my $self = shift;
    my $id = shift // $self->id;
    return sprintf('bin:%s', $id);
}

1;
