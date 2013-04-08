#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'SMTPbin' ) || print "Bail out!\n";
}

diag( "Testing SMTPbin $SMTPbin::VERSION, Perl $], $^X" );
