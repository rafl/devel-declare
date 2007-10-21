use strict;
use warnings;
use Test::More 'no_plan';

use Devel::Declare ();

BEGIN {
  Devel::Declare->build_sub_installer('Foo', 'bar', '&')
                ->(sub { $_[0]->("woot"); });
}

my $args;

{
  package Foo;

  bar { $args = join(', ', @_); };
}

is($args, 'woot', 'sub installer worked');
