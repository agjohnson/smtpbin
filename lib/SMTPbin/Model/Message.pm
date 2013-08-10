package SMTPbin::Model::Message;

use strict;
use warnings;
use 5.010;

use Mouse;
use AnyEvent;
use Data::UUID;

use SMTPbin::Model;
use SMTPbin::Model::Bin;
use SMTPbin::Model::Email;
use SMTPbin::Util qw/jsonify/;


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

has 'policy' => (
    is => 'rw'
);

# Class methods for creating message objects
sub from_email {
    my $class = shift;
    my $raw = shift;

    my $email = SMTPbin::Model::Email->new($raw);

    if (my $bin_id = $email->header('X-SMTPbin-Id')) {
        my $policy = $email->header('X-SMTPbin-Policy');
        return $class->new(
            email => $email,
            bin => $bin_id,
            policy => (defined $policy) ? $policy : 'save'
        );
    }
}

sub find {
    my $class = shift;
    my %args = @_;

    # Pull out args
    my $id = $args{id};
    my $cb = $args{cb};

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
                email => SMTPbin::Model::Email->from_json(
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

sub save {
    my $self = shift;
    my $cv = AnyEvent->condvar;

    # Add message
    if ($self->policy eq 'write') {
        $cv->begin;
        $self->db->multi;
        $self->db->hset($self->db_key, 'bin', $self->json_attr('bin'));
        $self->db->hset($self->db_key, 'email', $self->json_attr('email'));
        $self->db->expire($self->db_key, 600);
        $self->db->exec(sub { $cv->end });
    }

    # Add to bin
    $cv->begin;
    my $bin = SMTPbin::Model::Bin->new(
        id => $self->bin
    );
    my $cv1;
    if ($self->policy eq 'write') {
        $cv1 = $bin->add($self);
    }
    else {
        $cv1 = $bin->count($self);
    }
    $cv1->cb(sub { $cv->end });

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
    return $self->email->header('Subject')
      if (defined $self->email);
}

sub date {
    my $self = shift;
    return $self->email->header('Date')
      if (defined $self->email);
}

sub from {
    my $self = shift;
    return $self->email->header('From')
      if (defined $self->email);
}

sub recipient {
    my $self = shift;
    return $self->email->header('To')
      if (defined $self->email);
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

sub TO_JSON {
    my $self = shift;
    return {
        id => $self->id,
        bin => $self->bin,
        recipient => $self->recipient,
        sender => $self->from,
        subject => $self->subject
    };
}

1;
