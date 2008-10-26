
use strict;

use Test::More tests => 3;

use lib 'lib';
use Devel::Declare::MethodInstaller::Simple;

# suppress warnings
sub Devel::Declare::MethodInstaller::Simple::parse_proto { '' }

BEGIN {
  Devel::Declare::MethodInstaller::Simple->install_methodhandler(
    name => 'method',
    into => 'main',
  );
}

is eval { foo() } , undef;
like $@, qr/subroutine &main::foo/;

method foo { 1 }

is foo(), 1;

