use strict;
use warnings;
use Test::More tests => 1;

sub fun :lvalue { return my $sv; }

sub handle_fun {
  my ($usepack, $use, $inpack, $name, $proto) = @_;
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

my $foo = fun ($a,
$b) { "woot" };

is($foo->(), "\$a,\n\$b: woot", 'proto declarator ok');
