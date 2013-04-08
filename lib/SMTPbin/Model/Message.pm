package SMTPbin::Model::Message;

use Mouse;
use AnyEvent;
use Data::UUID;

extends 'SMTPbin::Model';
use SMTPbin::Model::Message;

# Attributes
has 'id' => (
    is => 'rw',
    builder => '_build_id'
);

has 'bin' => (
    is => 'rw'
);

has 'headers' => (
    is => 'rw'
);

has 'parts' => (
    is => 'rw'
);

has 'meta' => (
    is => 'rw'
);

# Class methods for creating message objects
sub from_email {
    my $class = shift;
    my $message = shift;

    if (my $bin = $message->header('X-SMTPbin-Id')) {
        return $class->new(
            # TODO create a bin object
            bin => $bin
        );
    }
}

sub find {
    my ($class, $id, $cb) = @_;
    my $cv = AnyEvent->condvar(
        cb => $cb
    );
    $class->db->hgetall($class->db_key($id), sub {
        my $ret = shift;
        if (@{$ret}) {
            my %args = @{$ret};
            my $msg = $class->new(
                id => $id
            );
            $msg->json_attr($_, $args{$_}) for keys %args;
            $cv->send($msg);
        }
        else {
            $cv->send(undef);
        }
    });
    return $cv;
}

sub save {
    my $self = shift;
    my $cv = AnyEvent->condvar;

    # Add message
    $cv->begin;
    $self->db->multi;
    $self->db->hset($self->db_key, $_, $self->json_attr($_))
      for qw/bin headers parts meta/;
    $self->db->expire($self->db_key, 600);
    $self->db->exec(sub { $cv->end });

    # Add to Bin
    $cv->begin;
    my $bin = SMTPbin::Model::Bin->new(
        id => $self->bin
    );
    my $cv_bin = $bin->add($self);
    $cv_bin->cb(sub { $cv->end });

    return $cv;
}

# Attributes
sub _build_id {
    my $self = shift;
    return Data::UUID->new->create_str;
}

sub url {
    return sprintf('/bin/%s', shift->id);
}

sub db_key {
    my $self = shift;
    my $id = shift // $self->id;
    return sprintf('message:%s', $id);
}

1;
