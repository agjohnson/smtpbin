package SMTPbin::Backend;

use 5.010;
use strict;
use warnings;

use Plack::Response;
use Plack::Request;
use Text::Xslate;
use FindBin;
use Cwd;
use AnyEvent::Log;

use Exporter 'import';
our @EXPORT = qw/
    route get post put delete
    template render abort
    logger
/;

our $Path = Cwd::abs_path($FindBin::Bin . "/view");
our $Routes = {};

our $Logger = AnyEvent::Log::ctx;
$Logger->log_to_file('errlog');


sub app {
    my $env = shift;

    my $req = Plack::Request->new($env);
    my $path = $req->path_info;
    my $method = $req->method;

    foreach my $route (@{$Routes->{$method}}) {
        my $route_path = $route->{path};
        if (my @args = ($path =~ m#$route_path#)) {
            return $route->{callback}($req, @args);
        }
    }

    return abort(404);
}

# Building routes
sub route {
    my ($method, $path, $callback) = @_;
    push(@{$Routes->{uc $method}}, {
        path => $path,
        callback => $callback
    });
}

sub get ($&) { route('GET', @_) }
sub post ($&) { route('POST', @_) }
sub put ($&) { route('PUT', @_) }
sub delete ($&) { route('DELETE', @_) }

# Return HTTP failure
sub abort ($) {
    my $code = shift;
    my $t_file = 'error.html';
    #return render(template('error.html', { error => $code }));
    given ($code) {
        when (404) { $t_file = '404.html' }
        when (500) { $t_file = '500.html' }
    }
    return render(template($t_file));
}

# Return response rendered from Xslate template
sub template ($;$) {
    my $template = shift;
    my $args = ref $_[0] eq 'HASH' ? $_[0] : {@_};

    # Try to process the template, croak on errors, return response
    my $t = Text::Xslate->new(
        path => './view/',
        cache => 0,
        suffix => '.tpl',
        syntax => 'Kolon',
        tag_start => '{%',
        tag_end => '%}',
        die_handler => sub {
            die("Template error: @_");
        },
        warn_handler => sub {
            die("Template warning: @_");
        },
        function => {
            truncate => \&_util_truncate
        }
    );

    my $output = $t->render($template, $args)
      or die 'Problem with template';

    return Plack::Response->new(
        200,
        {'Content-type' => 'text/html'},
        [$output]
    );
}

sub _util_truncate {
    my $string = shift;
    my $length = shift // 70;

    if (length($string) > $length) {
        $string =~ s/^(.{0,$length})\b.*$/$1&#x2026;/s;
    }

    return $string;
}

# Renders a response
sub render ($) {
    my $val = shift;
    if (ref $val eq 'Plack::Response') {
        return $val->finalize;
    }
    return Plack::Response->new(
        200,
        {'Content-type' => 'text/html'},
        [$val]
    )->finalize;
}

# Logging
sub logger ($$) {
    $Logger->log(@_);
}

1;
