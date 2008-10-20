
use strict;
use warnings;

use Test::More tests => 2;                      # last test to print

use Devel::Declare 'method' => sub{};

sub lowercase {
        lc $_[0];
}

is uc("bar\x{263a}"), "BAR\x{263a}";
is lowercase("FOO\x{263a}"), "foo\x{263a}";

=pod

This test does *not* segfault for me like t/segv_utf8_lc.t

=cut

