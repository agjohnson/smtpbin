package SMTPbin::Pages;

use 5.010;
use strict;
use warnings;

use File::stat;
use FindBin;
use Plack::Response;

use SMTPbin::Backend;
use SMTPbin::Model::Message;
use SMTPbin::Model::Bin;
use SMTPbin::Model::Stats;
use SMTPbin::Util qw/jsonify/;


get '^[/]*$' => sub {
    return sub {
        my $respond = shift;
        my $ret = Plack::Response->new();
        $ret->redirect('/index', 302);
        return $respond->(render $ret);
    };
};

get '^/index$' => sub {
    return sub {
        my $respond = shift;
        my $res = template('index.tpl');
        $res->headers->header('Cache-Control' => 'max-age=7200');
        return $respond->(render $res);
    };
};

# Message
get '^/view/message/([0-9A-Za-z\-]+)($|.txt$|.html$)' => sub {
    my ($req, $id, $view) = @_;

    return sub {
        my $respond = shift;

        # Set up sub-views
        logger(debug => sprintf('Searching for message: %s', $id));
        my $cv; $cv = SMTPbin::Model::Message->find(
            id => $id,
            cb => sub {
                my $msg = shift->recv;
                undef $cv;
                if (defined $msg) {
                    # Message actions
                    if ($view eq '/delete') {
                        _message_delete($respond, $msg);
                    }
                    else {
                        _message_view($respond, $msg, $view);
                    }
                }
                else {
                    return $respond->(abort(404));
                }
            }
        );
    };
};

sub _message_view {
    my ($respond, $msg, $view) = @_;

    # Update state
    $msg->state('read');
    $msg->update;

    # Show message
    if ($view eq '') {
        _message_view_full($respond, $msg);
    }
    elsif ($view eq '.txt') {
        _message_view_plain($respond, $msg);
    }
    elsif ($view eq '.html') {
        _message_view_html($respond, $msg);
    }
    else {
        return $respond->(abort(404));
    }
}

sub _message_view_full {
    my ($respond, $msg) = @_;
    my $part = $msg->email->part_type('text/plain') // $msg->email;
    return $respond->(render template 'message.tpl', {
        message => $msg,
        part => $part,
        body => $part->body,
        headers => $msg->headers,
    });
}

sub _message_view_plain {
    my ($respond, $msg) = @_;
    my $res = Plack::Response->new(200);
    $res->content_type('text/plain');
    $res->body($msg->email->as_string);
    return $respond->(render $res);
}

sub _message_view_html {
    my ($respond, $msg) = @_;
    my $part = $msg->email->part_type('text/html') //
        $msg->email->part_type('text/plain') //
        $msg->email;
    my $res = Plack::Response->new(200);
    $res->content_type('text/html');
    $res->body($part->body);
    return $respond->(render $res);
}

# Bin Pages
get '^/view/bin$' => sub {
    my $req = shift;
    return sub {
        my $respond = shift;
        return $respond->(render template 'bin.tpl');
    };
};

get '^/view/bin/random$' => sub {
    my $req = shift;
    my $bin = SMTPbin::Model::Bin->random;
    return sub {
        my $respond = shift;
        my $ret = Plack::Response->new();
        $ret->redirect($bin->url, 302);
        return $respond->(render $ret);
    };
};

get '^/view/bin/([\w\-\_]+)$' => sub {
    my ($req, $id, $type) = @_;

    # TODO more search fields here
    my %search = map { +$_ => $req->param($_) } qw/
        user
    /;

    return sub {
        my $respond = shift;
        logger(debug => sprintf('Searching for bin: %s', $id));
        my $cv; $cv = SMTPbin::Model::Bin->find(
            id => $id,
            search => \%search,
            cb => sub {
                my $bin = shift->recv;
                undef $cv;
                if (defined $type and $type eq '.json') {
                    my $res = Plack::Response->new(200);
                    $res->content_type('application/json');
                    $res->body(jsonify($bin));
                    return $respond->(render $res);
                }
                else {
                    return $respond->(render template 'bin.tpl', {
                        id => $id,
                        messages => (length $bin->messages) ?
                            $bin->messages : undef,
                        search => \%search
                    });
                }
            }
        );
    }
};
