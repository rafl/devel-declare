use strict;
use warnings;
use Test::More tests => 3;

sub handle_fun {
  my $pack = shift;
  my $linestr = Devel::Declare::get_linestr();
  my $pos = length($linestr);
  Devel::Declare::toke_skipspace(length($linestr));
  Devel::Declare::set_linestr($linestr);
}

use Devel::Declare;
sub fun($) {}
BEGIN {
  Devel::Declare->setup_for(
    __PACKAGE__,
    { fun => { const => \&handle_fun } }
  );
}


fun 1;
ok 0; this line is deleted by handler
;
ok 1;

# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# min

# pos 8192 occurs between these two lines
fun 1;
ok 0; this line is deleted by handler
;
ok 1;

# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless co

# pos 16384 occurs between these two lines
fun 1;
ok 0; this line is deleted by handler
;
ok 1;

# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary
# mindless comment lines to pad out the test program to the next block boundary

# file size slightly exceeds 32768

1;
