use 5.010;
use strict;
use warnings;

use Test::More;
plan tests => 15;

use SMTPbin::Model::Email;
use Data::Dumper;

# Save message from email
my $email = <<EMAIL;
X-SMTPbin-Id: lksdhglaksdhlgkhasd
Subject: test
MIME-Version: 1.0
Content-type: multipart/mixed; boundary=foobar

MAIN BODY

--foobar
Content-type: text/plain

PLAIN BODY

--foobar
Content-type: text/html

HTML BODY

--foobar--
EMAIL

my $msg = SMTPbin::Model::Email->new($email);
is($msg->content_type, 'multipart/mixed; boundary=foobar', 'Main content type');
is($msg->body, "MAIN BODY\n\n", 'Main body');

my $part;
$part = $msg->part_type('text/plain');
is($part->content_type, 'text/plain', 'Part content type');
is($part->body, "PLAIN BODY\n\n", 'Part body');

$part = $msg->part_type('text/html');
is($part->content_type, 'text/html', 'Part content type');
is($part->body, "HTML BODY\n\n", 'Part body');

my $json = $msg->TO_JSON;
ok(defined($json->{body}), 'JSON export body');
is(ref $json->{body}, '', 'JSON body reference type');
ok(defined($json->{headers}), 'JSON export headers');
is(ref $json->{headers}, 'ARRAY', 'JSON body reference type');
ok(defined($json->{parts}), 'JSON export parts');
is(ref $json->{parts}, 'ARRAY', 'JSON body reference type');

my $rmsg = SMTPbin::Model::Email->from_json($json);
ok(defined($rmsg), 'Reverse message from JSON');
is($rmsg->header('Subject'), 'test', 'Reverse message subject');
is($rmsg->header('X-SMTPbin-Id'), 'lksdhglaksdhlgkhasd', 'Reverse message bin');
