package SMTPbin::Model::Email;

use strict;
use warnings;
use 5.010;

use base 'Email::MIME';

sub TO_JSON {
    return shift->as_string;
}

1;
