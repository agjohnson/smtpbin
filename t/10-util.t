use 5.010;
use strict;
use warnings;

use Test::More;
use Test::MockModule;

plan tests => 4;

use SMTPbin::Util qw/config/;
use Data::Dumper;

{
    my $mocker = Test::MockModule->new('Config::Any');
    $mocker->mock('load_stems', sub {
        return {
            'config.json' => {
                'foobar' => 'foobar',
                'foo' => 'foo',
                'bar' => 'bar',
                'nested' => {
                    'foobar' => 'foobar'
                }
            },
            'config.yaml' => {
                'foobar' => 'NOT FOOBAR'
            }
        }
    });

    is(config->{foo}, 'foo', 'Foo config element');
    is(config->{foobar}, 'foobar', 'Foobar config element');
    is(config->{bar}, 'bar', 'Bar config element');
    is(ref config->{nested}, 'HASH', 'Nested config hash');
}
