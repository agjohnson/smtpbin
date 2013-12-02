use 5.010;
use strict;
use warnings;

use Test::More;
plan tests => 9;

use SMTPbin::Pages;
use SMTPbin::API;
use SMTPbin::Backend;

# Mock routes
# TODO test other methods
my $route_count = scalar(@{$SMTPbin::Backend::Routes->{GET}});
for my $route (0 .. ($route_count - 1)) {
    $SMTPbin::Backend::Routes->{GET}->[$route]->{callback} = sub {
        my $req = shift;
        return \@_;
    }
}

# GET Routes
# TODO test other methods
sub _get_route {
    my $path = shift;
    foreach my $route (@{$SMTPbin::Backend::Routes->{GET}}) {
        my $route_path = $route->{path};
        if (my @args = ($path =~ m#$route_path#)) {
            return $route->{callback}(undef, @args);
        }
    }
}

# Test routes
is(_get_route('/')->[0], 1);
is(_get_route('/view/message/foobar')->[0], 'foobar');
is(_get_route('/view/message/foobar')->[1], '');
is(_get_route('/view/message/foobar.txt')->[0], 'foobar');
is(_get_route('/view/message/foobar.txt')->[1], '.txt');
is(_get_route('/view/message/foobar.html')->[0], 'foobar');
is(_get_route('/view/message/foobar.html')->[1], '.html');
is(_get_route('/message/foobar')->[0], 'foobar');
is(_get_route('/message/foobar')->[1], undef);
