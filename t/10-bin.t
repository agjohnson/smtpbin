use 5.010;
use strict;
use warnings;

use Test::MockModule;
use Test::More;
plan tests => 2;

use SMTPbin::Model::Message;
use SMTPbin::Model::Bin;
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

    my $bin;

    # Save message
    SMTPbin::Model::Bin->connect;
    my $msg = SMTPbin::Model::Message->new(
        id => 'testbin',
        bin => 'testbin',
        email => SMTPbin::Model::Email->create(
            body => 'test',
            header => [
                'Test' => 'test'
            ]
        )
    );
    my $cv1 = $msg->save;
    $cv1->recv;

    # Fetch email
    $msg = SMTPbin::Model::Bin->find('testbin', sub {
        my $found = shift->recv;
        if (defined $found) {
            pass('Fetch bin');
            is($found->{id}, 'testbin', 'Find bin');
        }
    });
}

