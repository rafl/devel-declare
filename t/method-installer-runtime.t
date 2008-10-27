
use strict;

use Test::More tests => 2;

use Devel::Declare::MethodInstaller::Simple;

# suppress warnings
sub Devel::Declare::MethodInstaller::Simple::parse_proto { '' }

BEGIN {
  Devel::Declare::MethodInstaller::Simple->install_methodhandler(
    name => 'method',
    into => 'main',
  );
}

ok(!main->can('foo'), 'foo() not installed yet');

method foo { }

ok(main->can('foo'), 'foo() installed at runtime');

