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
    is => 'rw',
    default => sub { [] }
);


# Class methods for instanciation
sub random {
    my $class = shift;
    $class->new(id => lc(Data::UUID->new->create_str));
}

sub find {
    my $class = shift;
    my %args = @_;

    use Data::Dumper;
    logger(debug => Dumper(\%args));

    # Pull args out
    my $id = $args{id};
    my $search = $args{search} // {};
    my $cb = $args{cb} // sub { };

    my $bin = $class->new(id => $id);
    my $rcv; $rcv = $class->db->lrange($class->db_key($id), 0, -1, sub {
        my $ret = shift;
        undef $rcv;
        my $cv = AnyEvent->condvar;
        $cv->cb($cb);
        if (@{$ret}) {
            logger(debug => "Found bin with messages on lookup: ${id}");
            for my $msg_id (@{$ret}) {
                $cv->begin(sub { $cv->send($bin) });
                SMTPbin::Model::Message->find(id => $msg_id, cb => sub {
                    my $msg = shift->recv;
                    $cv->end if (!defined $msg);

                    # Search match
                    if ($search->{user}) {
                        my $recipient = $msg->header('To');
                        my $user = $search->{user};
                        if ($recipient !~ m/
                                    ${user}
                                    (?:\+\w+)?\@smtpbin\.org$
                                /x) {
                            return $cv->end;
                        };
                    }

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
    $self->db->lpush($self->db_key, $msg->id);
    $self->db->expire($self->db_key, 600);
    $self->db->exec(sub { $cv->end });

    $cv->begin;
    my $cv1 = $self->count;
    $cv1->cb(sub { $cv->end });

    return $cv;
}

sub count {
    my ($self) = @_;
    my $stats = SMTPbin::Model::Stats->new(
        id => $self->db_key
    );
    return $stats->add('recv', 1);
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
        messages => [
            (defined $self->messages) ?
              map { $_ } @{$self->messages} : undef
        ]
    };
}

1;
