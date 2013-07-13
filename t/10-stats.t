use 5.010;
use strict;
use warnings;

use Test::MockModule;
use Test::More;
plan tests => 4;

use SMTPbin::Model::Stats;

# TODO Mock redis here
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

    # Save message
    SMTPbin::Model::Stats->connect;
    my $stats = SMTPbin::Model::Stats->new(
        id => 'bin:test',
    );
    my $cv = $stats->add('recv', 1);
    undef $stats;

    $cv->cb(sub {
        pass('Add event triggered');
        my $stats = SMTPbin::Model::Stats->find('bin:test', sub {
            my $found = shift->recv;
            pass('Find event triggered');
            ok(defined $found, 'Stats received');
            is($found->data->{recv}, 1, 'Stats count okay');
        });
    });
    $cv->recv;
}
