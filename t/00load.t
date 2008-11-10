use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    $ENV{PERL_DL_NONLAZY} = 1;
    use_ok('Devel::Declare');
}
