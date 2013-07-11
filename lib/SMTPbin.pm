package SMTPbin;

use 5.010;
use strict;
use warnings;

=head1 NAME

SMTPbin - SMTPbin.org

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

SMTPbin.org <3 email

=cut

use SMTPbin::Backend;
use SMTPbin::Pages;
use SMTPbin::Model;
use SMTPbin::Util qw/config/;

use Plack::Builder;
use Plack::Middleware::Static;

sub app {
    builder {
        SMTPbin::Model->connect;
        enable(
            'Plack::Middleware::Static',
            path => sub { s#^/static/## },
            root => 'static/'
        );
        enable('Debug')
          if (config->{debug});
        mount '/' => \&SMTPbin::Backend::app;
    }
}

=head1 AUTHOR

Anthony Johnson, C<< <aj at ohess.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Anthony Johnson.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

1;
