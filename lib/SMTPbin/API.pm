package SMTPbin::API;

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
use SMTPbin::Util qw/jsonify decode_body/;

# General API functions
sub respond {
    my ($respond, $status, $data) = @_;
    $status //= 200;
    my $res = Plack::Response->new($status);
    $res->content_type('application/json');
    $res->body(jsonify($data));
    return $respond->(render $res);
}

# Message API
route($_, '^/message/([0-9A-Za-z\-]+)$', sub {
    my ($req, $id) = @_;

    return sub {
        my $respond = shift;

        logger(debug => sprintf('Fetching message: %s', $id));
        my $cv; $cv = SMTPbin::Model::Message->find(
            id => $id,
            cb => sub {
                my $msg = shift->recv;
                undef $cv;

                # If we have a message, perform action, otherwise give 404
                if (defined $msg) {
                    if ($req->method eq 'GET') {
                        return respond($respond, 200, $msg->email);
                    }
                    elsif ($req->method eq 'PUT') {
                        logger(debug => sprintf('Updating message: %s', $id));
                        my $data = decode_body($req);
                        if (defined $data->{state}) {
                            $msg->state($data->{state});
                            my $cv_inner = $msg->update;
                            $cv_inner->cb(sub {
                                return respond($respond);
                            });
                        }
                    }
                    elsif ($req->method eq 'DELETE') {
                        logger(debug => sprintf('Deleting message: %s', $id));
                        my $cv_inner = $msg->delete;
                        $cv_inner->cb(sub {
                            return respond($respond, 200, {
                                result => JSON::true
                            });
                        });
                    }
                }
                else {
                    return respond($respond, 404, {
                        error => 'Missing message'
                    });
                }
            }
        );
    }
}) foreach (qw/GET PUT DELETE/);

# Bin API
get '^/bin/([\w\-\_]+)$' => sub {
    my ($req, $id) = @_;

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
                return respond($respond, 200, $bin);
            }
        );
    }
};

get '^/bin/([\w\-\_]+)/stats$' => sub {
    my ($req, $id) = @_;
    $id = sprintf('bin:%s', $id);
    return sub {
        my $respond = shift;
        logger(debug => sprintf('Searching for stats: %s', $id));
        my $cv; $cv = SMTPbin::Model::Stats->find(
            id => $id,
            cb => sub {
                my $stats = shift->recv;
                undef $cv;
                return respond($respond, 200, $stats);
            }
        );
    }
};
