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


sub mail {
    my $class = shift;

    # TODO make this all configurable
    my $smtpd = AnyEvent::SMTP::Server->new(
        host => undef,
        port => 32001
    );
    $smtpd->reg_cb(
        mail => \&recv_message
    );
    $smtpd->start;
    print $smtpd;

    # TODO replace the polikcy server start mehtod to not block on recv
    my $app = AnyEvent::Postfix::Policy->new();
    $app->rule(
        recipient => qr/\@smtpbin.org$/,
        cb => sub { AnyEvent::Postfix::Policy::Response->new(
            action => 'filter',
            message => 'smtp:127.0.0.1:32001'
        )}
    );
    $app->run(undef, 32002);

    # TODO return a guard condvar?
}

sub recv_message {
    my $mail = shift;
    my $msg = SMTPbin::Model::Message->from_email($mail->{data});
    $msg->save();
}

1;
