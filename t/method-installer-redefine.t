use strict;
use warnings;
use Test::More tests => 4;
use Test::Warn;
use Devel::Declare::MethodInstaller::Simple;

BEGIN {
  Devel::Declare::MethodInstaller::Simple->install_methodhandler(
    name => 'method',
    into => 'main',
  );
}

BEGIN {
  no warnings 'redefine';
  Devel::Declare::MethodInstaller::Simple->install_methodhandler(
    name => 'method_quiet',
    into => 'main',
  );
}

ok(!main->can('foo'), 'foo() not installed yet');

method foo {
    $_[0]->method
}

use Test::Warn;

ok(main->can('foo'), 'foo() installed at runtime');

warnings_like {
    method foo {
        $_[0]->method;
    }
} qr/redefined/;

warnings_are {
    method_quiet foo {
        $_[0]->method;
    }
} [], 'no warnings';
