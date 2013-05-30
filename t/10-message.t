use 5.010;
use strict;
use warnings;

use Test::MockModule;
use Test::More;
plan tests => 10;

use SMTPbin::Model::Message;
use Data::Dumper;

# TODO Mock redis here
{
    my $mocker = Test::MockModule->new('AnyEvent::Redis');
    $mocker->mock('new', sub {
        bless {
            DATA => {}
        }, shift;
    });
    $mocker->mock($_, sub {}) for qw/expire multi/;
    $mocker->mock('exec', sub {
        my ($self, $cb) = @_;
        $cb->() if ($cb);
    });
    $mocker->mock('hset', sub {
        my ($self, $key, $hkey, $value, $cb) = @_;
        $self->{DATA}->{$key} = {}
          if (!defined $self->{DATA}->{$key});
        $self->{DATA}->{$key}->{$hkey} = $value;
        $cb->() if ($cb);
    });
    $mocker->mock($_, sub {
        my ($self, $key, $cb) = @_;
        my $data = $self->{DATA}->{$key};
        my @pairs;
        if (ref $data eq 'HASH') {
            @pairs = %{$data};
        }
        else {
            @pairs = @{$data};
        }
        $cb->(\@pairs) if ($cb);
    }) for qw/smembers hgetall/;
    $mocker->mock('sadd', sub {
        my ($self, $key, $value) = @_;
        push(@{$self->{DATA}->{$key}}, $value);
    });

    my $msg;

    # Save message
    SMTPbin::Model::Message->connect;
    $msg = SMTPbin::Model::Message->new(
        id => 'test',
        body => 'test',
        parts => [],
        bin => 'test',
        headers => []
    );
    my $cv1 = $msg->save;
    $cv1->cb(sub {
        pass('Saving message');
    });
    $cv1->recv;

    # Fetch email
    $msg = SMTPbin::Model::Message->find('test', sub {
        my $found = shift->recv;
        if (defined $found) {
            pass('Fetch message');
            is($found->{body}, 'test', 'Fetched body');
            is($found->{id}, 'test', 'Fetched id');
            is($found->{bin}, 'test', 'Fetched bin');
        }
    });

    # Save message from email
    my $email = <<EMAIL;
X-SMTPbin-Id: lksdhglaksdhlgkhasd
Subject: test

Test
EMAIL

    $msg = SMTPbin::Model::Message->from_email($email);
    my $cv2 = $msg->save;
    $cv2->cb(sub {
        pass('Message from email');
    });
    $cv2->recv;
}

# _header_from_pairs
my @pairs = qw/a b c d e f g h/;
my %matches = @pairs;
my $headers = SMTPbin::Model::Message->_headers_from_pairs(@pairs);
foreach my $header (@{$headers}) {
    my $k = $header->{header};
    my $v = $header->{value};
    my $match = $matches{$k};
    is($match, $v, "Testing header from pairs");
}
