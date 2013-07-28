use 5.010;
use strict;
use warnings;

use Test::MockModule;
use Test::More;
plan tests => 9;

use SMTPbin::Model::Message;
use SMTPbin::Model::Email;
use Data::Dumper;


{
    my $mocker = Test::MockModule->new('AnyEvent::Redis');
    $mocker->mock('new', sub {
        bless {
            DATA => {}
        }, shift;
    });
    $mocker->mock('connect', sub {
        my ($self, $cb) = @_;
        $cb->() if ($cb);
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
    $mocker->mock('hincrby', sub {
        my ($self, $key, $hkey, $value, $cb) = @_;
        $self->{DATA}->{$key} = {}
          if (!defined $self->{DATA}->{$key});
        $self->{DATA}->{$key}->{$hkey} = 0
          if (!defined $self->{DATA}->{$key}->{$hkey});
        $self->{DATA}->{$key}->{$hkey} += $value;
        $cb->() if ($cb);
    });
    $mocker->mock($_, sub {
        my ($self, $key) = @_;
        my $cb = pop @_;
        my $data = $self->{DATA}->{$key};
        my @pairs;
        if (ref $data eq 'HASH') {
            @pairs = %{$data};
        }
        else {
            @pairs = @{$data};
        }
        $cb->(\@pairs) if ($cb);
    }) for qw/lrange hgetall/;
    $mocker->mock('lpush', sub {
        my ($self, $key, $value) = @_;
        push(@{$self->{DATA}->{$key}}, $value);
    });

    my $msg;

    # Save message
    SMTPbin::Model::Message->connect;
    $msg = SMTPbin::Model::Message->new(
        id => 'test',
        bin => 'test',
        email => SMTPbin::Model::Email->create(
            id => 'test',
            header => [
                'X-SMTPbin-Id' => 'test',
            ],
            body => 'test'
        )
    );
    my $cv1 = $msg->save;
    $cv1->cb(sub {
        pass('Saving message');
    });
    $cv1->recv;

    # Email encoding
    my $json = $msg->json_attr('email');
    ok($json, 'Can encode email');
    isnt($json, 'null', 'JSON encoded email properly');

    # Fetch email
    $msg = SMTPbin::Model::Message->find(id => 'test', cb => sub {
        my $found = shift->recv;
        if (defined $found) {
            pass('Fetch message');
            is($found->body, 'test', 'Fetched body');
            is($found->id, 'test', 'Fetched id');
            is($found->bin, 'test', 'Fetched bin');
        }
    });

    # Save message from email
    my $email = <<EMAIL;
X-SMTPbin-Id: lksdhglaksdhlgkhasd
Content-type: text/html
Subject: test

Test
EMAIL

    $msg = SMTPbin::Model::Message->from_email($email);
    is($msg->bin, 'lksdhglaksdhlgkhasd', 'Bin name from email');
    my $cv2 = $msg->save;
    $cv2->cb(sub {
        pass('Message from email');
    });
    $cv2->recv;
}
