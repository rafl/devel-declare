use strict;
use warnings;
use Test::More 'no_plan';

sub action (&) { return shift; }

sub handle_action {
  return (undef, undef, 'my ($self, $c) = (shift, shift);');
}

use Devel::Declare;
use Devel::Declare action => [ DECLARE_NONE, \&handle_action ];

my $args;

my $a = action {
  $args = join(', ', $self, $c);
};

$a->("SELF", "CONTEXT");

is($args, "SELF, CONTEXT", "args passed ok");
