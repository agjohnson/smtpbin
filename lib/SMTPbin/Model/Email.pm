package SMTPbin::Model::Email;

use strict;
use warnings;
use 5.010;

use base 'Email::MIME';

sub TO_JSON {
    my $self = shift;
    return {
        headers => [$self->_json_headers],
        body => $self->_json_body,
        parts => [$self->_json_parts]
    };
}

sub from_json {
    my ($class, $json) = @_;

    if (defined $json->{parts}) {
        my @parts;
        for my $part (@{$json->{parts}}) {
            push(@parts, $class->create(
                attributes => {
                    encoding => '8bit',
                    charset => 'utf8'
                },
                body_str => $part->{body},
                header_str => $part->{headers}
            ));
        }
        return $class->create(
            attributes => {
                encoding => '8bit',
                charset => 'utf8'
            },
            header_str => $json->{headers},
            parts => [@parts]
        );
    }
    else {
        return $class->create(
            attributes => {
                encoding => '8bit',
                charset => 'utf8'
            },
            header_str => $json->{headers},
            body_str => $json->{body}
        );
    }
}

sub _json_headers {
    my $self = shift;
    return $self->header_pairs;
}

sub _json_body {
    my $self = shift;
    return $self->body;
}

sub _json_parts {
    my $self = shift;
    my @parts;
    $self->walk_parts(sub {
        my $part = shift;
        return if $part->subparts;

        push(@parts, {
            body => &_json_body($part),
            headers => [&_json_headers($part)]
        });
    });
    return @parts;
}

sub part_type {
    my ($self, $type) = @_;

    for my $part ($self->parts) {
        if ($part->content_type eq $type) {
            return $part;
        }
    }
}

1;
