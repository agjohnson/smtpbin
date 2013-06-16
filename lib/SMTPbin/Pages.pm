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
        my $res = template('index.html');
        $res->headers->header('Cache-Control' => 'max-age=7200');
        return $respond->(render $res);
    };
};

get '^/message/([0-9A-Za-z\-]+)($|.txt$|.html$|.json$)' => sub {
    my ($req, $id, $type) = @_;
    return sub {
        my $respond = shift;
        logger(debug => sprintf('Searching for message: %s', $id));
        my $cv; $cv = SMTPbin::Model::Message->find($id, sub {
            my $msg = shift->recv;
            undef $cv;
            if (defined $msg) {
                if ($type eq '.html') {
                    my $res = Plack::Response->new(200);
                    $res->content_type('text/html');
                    $res->body($msg->body);
                    return $respond->(render $res);
                }
                elsif ($type eq '.txt') {
                    my $res = Plack::Response->new(200);
                    $res->content_type('text/plain');
                    $res->body($msg->body);
                    return $respond->(render $res);
                }
                elsif ($type eq '.json') {
                    my $res = Plack::Response->new(200);
                    $res->content_type('application/json');
                    $res->body($msg->email->TO_JSON);
                    return $respond->(render $res);
                }
                elsif (defined $msg) {
                    return $respond->(render template 'message.html', {
                        body => $msg->body,
                        headers => $msg->headers,
                    });
                }
            }
            else {
                return $respond->(abort(404));
            }
        });
    }
};

get '^/bin/random$' => sub {
    my $req = shift;
    my $bin = SMTPbin::Model::Bin->random;
    return sub {
        my $respond = shift;
        my $ret = Plack::Response->new();
        $ret->redirect($bin->url, 302);
        return $respond->(render $ret);
    };
};

get '^/bin/([\w\-\_]+)$' => sub {
    my ($req, $id) = @_;
    return sub {
        my $respond = shift;
        logger(debug => sprintf('Searching for bin: %s', $id));
        my $cv; $cv = SMTPbin::Model::Bin->find($id, sub {
            my $bin = shift->recv;
            undef $cv;
            if (defined $bin) {
                return $respond->(render template 'bin.html', {
                    id => $id,
                    messages => (length $bin->messages) ?
                        $bin->messages : undef,
                });
            }
            else {
                return $respond->(render template 'bin.html', {
                    id => $id,
                    messages => undef
                });
            }
        });
    }
};
