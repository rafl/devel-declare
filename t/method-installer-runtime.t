use strict;
use warnings;
use Test::More tests => 2;
use Devel::Declare::MethodInstaller::Simple;

BEGIN {
  Devel::Declare::MethodInstaller::Simple->install_methodhandler(
    name => 'method',
    into => 'main',
  );
}

ok(!main->can('foo'), 'foo() not installed yet');

method foo { }

ok(main->can('foo'), 'foo() installed at runtime');

