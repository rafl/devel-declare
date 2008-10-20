=pod

This tests against a segfault when PL_parser becomes NULL temporarly, while
another module is loaded.

=cut

use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

use Devel::Declare 'method' => sub{};

sub lowercase {
        lc $_[0];
}

is lowercase("FOO\x{263a}"), "foo\x{263a}";
