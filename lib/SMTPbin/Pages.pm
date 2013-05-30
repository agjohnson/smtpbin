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

get '^/message/(\w+)$' => sub {
    my ($req, $id) = @_;
    return sub {
        my $respond = shift;
        logger(debug => sprintf('Searching for message: %s', $id));
        my $cv; $cv = SMTPbin::Model::Message->find($id, sub {
            my $msg = shift->recv;
            undef $cv;
            if (defined $msg) {
                return $respond->(render template 'message.html', {
                    body => 'BODY',
                    headers => $msg->headers,
                });
            }
            else {
                return $respond->(abort(404));
            }
        });
    }
};

get '^/bin/(\w+)$' => sub {
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
                    messages => $bin->messages,
                });
            }
            else {
                return $respond->(abort(404));
            }
        });
    }
};
