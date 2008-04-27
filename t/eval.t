use strict;
use warnings;
use Test::More 'no_plan';

sub method {
  my ($usepack, $name, $inpack, $sub) = @_;
  no strict 'refs';
  *{"${inpack}::${name}"} = $sub;
}

sub handle_method {
  my ($usepack, $use, $inpack, $name) = @_;
  return sub (&) { ($usepack, $name, $inpack, $_[0]); };
}

use Devel::Declare 'method' => \&handle_method;

eval "method bar ( ) { 42 }";

is( __PACKAGE__->bar, 42 );


