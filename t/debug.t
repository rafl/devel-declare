use strict;
use warnings;

use Test::More;

BEGIN {
  if($] eq "5.011002") {
    plan skip_all => "line debugging broken on 5.11.2";
  }
}

use Cwd qw/cwd/;
use FindBin qw/$Bin/;

$ENV{PERLDB_OPTS} = "NonStop";
$ENV{DD_DEBUG} = 1;
cwd("$Bin/..");

# Write a .perldb file so we make sure we dont use the users one
open PERLDB, ">", "$Bin/../.perldb" or die "Cannot open $Bin/../.perldb: $!";
close PERLDB;

$SIG{CHLD} = 'IGNORE';
$SIG{ALRM} = sub {
  fail("SIGALRM timeout triggered");
  kill(9, $$);
};

alarm 10;
my $output = `$^X -d t/debug.pl`;

like($output, qr/method new {}, sub {my \$self = shift;/,
  "replaced line string visible in debug lines");

done_testing;
