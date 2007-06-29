use strict;
use warnings;
use Test::More 'no_plan';

sub fun :lvalue { return my $sv; }

sub X { "what?" }

sub handle_fun {
  my ($pack, $use, $name, $proto) = @_;
  my $XX = sub (&) {
    my $cr = $_[0];
    return sub {
      return join(': ', $proto, $cr->());
    };
  };
  return (undef, $XX);
}

use Devel::Declare;
use Devel::Declare fun => [ DECLARE_PROTO, \&handle_fun ];

my $foo = fun ($a, $b) { "woot" };

is($foo->(), '$a, $b: woot', 'proto declarator ok');
is(X(), 'what?', 'X sub restored ok');
