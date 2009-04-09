use strict;
use warnings;
use Test::More tests => 14;

use Devel::Declare 'method' => sub {};

sub test_eval;

test_eval 'qq/method/';
test_eval '`method`';
test_eval 'qx/method/';
test_eval 'qr/method/';
test_eval '/method/';
test_eval 's/method//';
test_eval 'tr/method/METHOD/';
test_eval 'q/method/';
test_eval "'method'";
test_eval '"method"';
test_eval 'qw/method/';
test_eval '<<method;
tum ti tum
method';
test_eval 'no warnings "reserved"; open method, "</dev/null"';
test_eval '<method>';

sub test_eval {
    my $what = shift;
    eval $what;
    ok !$@, "$what" or d($@);
}
{
  my %seen;
  sub d { # diag the error the first time we get it
    my $err = shift;
    $err =~s/ at .*$//;
    $seen{$err}++ or diag $err;
  }
}
