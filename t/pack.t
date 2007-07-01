use strict;
use warnings;
use Test::More 'no_plan';

sub class { $_[0]->(); }

sub handle_class {
  my ($pack, $use, $name, $proto, $is_block) = @_;
  return (sub (&) { shift; }, undef, "package ${name};");
}

use Devel::Declare;
use Devel::Declare 'class' => [ DECLARE_PACKAGE, \&handle_class ];

my $packname;

class Foo::Bar {
  $packname = __PACKAGE__;
};

is($packname, 'Foo::Bar', 'Package saved ok');
is(__PACKAGE__, 'main', 'Package scoped correctly');
