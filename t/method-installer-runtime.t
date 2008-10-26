
use strict;

use Test::More tests => 3;

use Devel::Declare::MethodInstaller::Simple;

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

__END__
1..2
Use of uninitialized value $inject in concatenation (.) or string at /opt/perl/lib/site_perl/5.10.0/i686-linux/Devel/Declare/MethodInstaller/Simple.pm line 81.
ok 1
ok 2
ok 3
# Looks like you planned 2 tests but ran 3.
