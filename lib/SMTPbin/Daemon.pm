package SMTPbin::Daemon;

use 5.010;
use strict;
use warnings;

use AnyEvent;
use AnyEvent::Postfix::Policy;
use AnyEvent::SMTP::Server;
use Email::MIME;

use SMTPbin::Model::Message;
use SMTPbin::Model::Bin;
use SMTPbin::Util qw/config/;

sub mail {
    my $class = shift;

    # TODO make this all configurable
    my $smtpd = AnyEvent::SMTP::Server->new(
        host => config->{smtpd}->{host},
        port => config->{smtpd}->{port}
    );
    $smtpd->reg_cb(
        mail => \&recv_message
    );
    $smtpd->start;

    # TODO replace the polikcy server start mehtod to not block on recv
    my $app = AnyEvent::Postfix::Policy->new();
    $app->rule(
        recipient => qr/^(?:\w+|\w+\+(?:2\d\d|okay|ok))\@smtpbin.org$/,
        cb => sub { AnyEvent::Postfix::Policy::Response->new(
            action => 'ok',
            message => 'Accepted'
        )}
    );
    $app->rule(
        recipient => qr/^\w+\+(?:450|defer)\@smtpbin.org$/,
        cb => sub { AnyEvent::Postfix::Policy::Response->new(
            action => '450',
            message => 'Mailbox unavailable'
        )}
    );
    $app->rule(
        recipient => qr/^\w+\+451\@smtpbin.org$/,
        cb => sub { AnyEvent::Postfix::Policy::Response->new(
            action => '451',
            message => 'Temporary error'
        )}
    );
    $app->rule(
        recipient => qr/^\w+\+452\@smtpbin.org$/,
        cb => sub { AnyEvent::Postfix::Policy::Response->new(
            action => '452',
            message => 'Insufficient storage'
        )}
    );
    $app->rule(
        recipient => qr/^\w+\+(?:5\d\d|reject)\@smtpbin.org$/,
        cb => sub { AnyEvent::Postfix::Policy::Response->new(
            action => '500',
            message => 'Mailbox unavailable'
        )}
    );
    $app->run(
        config->{policy}->{host},
        config->{policy}->{port}
    );

    # TODO return a guard condvar?
}

sub recv_message {
    my ($conn, $mail) = @_;
    my $msg = SMTPbin::Model::Message->from_email($mail->{data});
    $msg->save();
}

1;
