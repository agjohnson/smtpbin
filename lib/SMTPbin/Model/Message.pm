package SMTPbin::Model::Message;

use Mouse;
use AnyEvent;
use Data::UUID;

extends 'SMTPbin::Model';
use SMTPbin::Model::Bin;

use Email::MIME;


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

has 'body' => (
    is => 'rw'
);

has 'meta' => (
    is => 'rw'
);

# Class methods for creating message objects
sub from_email {
    my $class = shift;
    my $raw = shift;
    my $email = Email::MIME->new($raw);

    if (my $bin_id = $email->header('X-SMTPbin-Id')) {
        # MIME then Single Part
        my @parts;
        if ($email->parts) {
            foreach my $part ($email->parts) {
                # TODO handle nested parts here?
                next if ($part->subparts);
                push(@parts, {
                    headers => $class->_headers_from_pairs(
                        $part->header_pairs
                    ),
                    body => $part->body
                })
            }
        }
        else {
            push(@parts, {
                headers => $class->_headers_from_pairs(
                    $email->header_pairs
                ),
                body => $email->body
            });
        }

        return $class->new(
            body => $email->body,
            parts => [@parts],
            headers => $class->_headers_from_pairs(
                $email->header_pairs
            ),
            bin => $bin_id
        );
    }
}

sub find {
    my ($class, $id, $cb) = @_;
    my $rcv; $rcv = $class->db->hgetall($class->db_key($id), sub {
        my $ret = shift;
        undef $rcv;
        my $cv = AnyEvent->condvar;
        $cv->cb($cb);
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
    return $rcv;
}

sub get_payload {
    my $self = shift;
    my $content_type = shift // 'text/plain';

    my $payload = $self->body;
    for my $part (@{$self->parts}) {
        for my $header (@{$part->{headers}}) {
            if (lc($header->{header}) eq 'content-type' and
                    $header->{value} eq $content_type) {
                $payload = $part->{body}
            }
        }
    }
}

sub save {
    my $self = shift;
    my $cv = AnyEvent->condvar;

    # Add message
    $cv->begin;
    $self->db->multi;
    $self->db->hset($self->db_key, $_, $self->json_attr($_))
      for qw/bin body headers parts meta/;
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

# Helpers
sub _headers_from_pairs {
    my ($self, @pairs) = @_;
    my @headers;
    while (@pairs) {
        my ($k, $v) = splice(@pairs, 0, 2);
        push(@headers, {
            header => $k,
            value => $v
        });
    }
    return \@headers;
}

1;
