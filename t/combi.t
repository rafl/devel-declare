use strict;
use warnings;
use Test::More 'no_plan';

sub method :lvalue {my $sv;}

sub handle_method {
  my ($usepack, $use, $inpack, $name, $proto) = @_;
  my $H = sub (&) { };
  if (defined $proto) {
    return (sub :lvalue {my $sv;}, $H);
  }
  return ($H);
}

use Devel::Declare;
use Devel::Declare method => [ DECLARE_NAME|DECLARE_PROTO, \&handle_method ];

method blah {

};

method () {

};

method wahey () {

};

ok(1, "Survived compilation");
