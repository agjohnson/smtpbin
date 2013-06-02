package SMTPbin::Model::Message;

use strict;
use warnings;
use 5.010;

use Mouse;
use AnyEvent;
use Data::UUID;

extends 'SMTPbin::Model';
use SMTPbin::Model::Bin;
use SMTPbin::Model::Email;


# Attributes
has 'id' => (
    is => 'rw',
    builder => '_build_id'
);

has 'bin' => (
    is => 'rw'
);

has 'email' => (
    is => 'rw',
    required => 1,
    handles => {
        header => 'header',
        body => 'body'
    }
);

# Class methods for creating message objects
sub from_email {
    my $class = shift;
    my $raw = shift;

    my $email = SMTPbin::Model::Email->new($raw);

    if (my $bin_id = $email->header('X-SMTPbin-Id')) {
        return $class->new(
            email => $email,
            bin => $bin_id
        );
    }
}

sub find {
    my ($class, $id, $cb) = @_;
    # TODO mouse introspect here, get fields
    my $rcv; $rcv = $class->db->hgetall($class->db_key($id), sub {
        my $ret = shift;
        undef $rcv;
        my $cv = AnyEvent->condvar;
        $cv->cb($cb);
        if (@{$ret}) {
            my %args = @{$ret};
            my $msg = $class->new(
                id => $id,
                bin => $class->json_attr('bin', $args{bin}),
                email => SMTPbin::Model::Email->new(
                    $class->json_attr('email', $args{email})
                )
            );
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
    # TODO check if is multipart here, get matching content type
    my $content_type = shift // 'text/plain';
    return $self->parts->{$content_type};
}

sub save {
    my $self = shift;
    my $cv = AnyEvent->condvar;

    # Add message
    $cv->begin;
    $self->db->multi;
    $self->db->hset($self->db_key, 'bin', $self->json_attr('bin'));
    $self->db->hset($self->db_key, 'email', $self->json_attr('email'));
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

# Helper accessors
sub subject {
    my $self = shift;
    return $self->email->header('Subject');
}

sub date {
    my $self = shift;
    return $self->email->header('Date');
}

sub from {
    my $self = shift;
    return $self->email->header('From');
}

# Helpers
sub headers {
    my $self = shift;
    my @pairs = $self->email->header_pairs;
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
