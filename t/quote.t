use strict;
use warnings;
use Test::More tests => 15;

use Devel::Declare 'method' => sub {};
use File::Spec;

sub test_eval;

QUOTE: {
    test_eval 'qq/method/';
    test_eval 'q/method/';
    test_eval "'method'";
    test_eval '"method"';
    test_eval 'qw/method/';
    test_eval '<<method;
tum ti tum
method';
    test_eval 'my $x = { method => 42 }';
}

SYSTEM: {
    test_eval 'sub {`method`}'; # compiled to prevent calling arbitrary exe!
    test_eval 'sub { qx{method} }';
}

REGEX: {
    local $_=''; # the passing results will act on $_
    test_eval 'qr/method/';
    test_eval '/method/';
    test_eval 's/method//';
    test_eval 'tr/method/METHOD/';
}

FILE: {
    test_eval q{ no warnings 'reserved'; open method, '<', File::Spec->devnull };
    test_eval '<method>';
}

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
