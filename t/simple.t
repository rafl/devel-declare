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

my ($args1, $args2);

method bar {
  $args1 = join(', ', @_);
};

method # blather
  baz
  # whee
{ # fweet
  $args2 = join(', ', @_);
};

__PACKAGE__->bar(qw(1 2));
__PACKAGE__->baz(qw(3 4));

is($args1, 'main, 1, 2', 'Method bar args ok');
is($args2, 'main, 3, 4', 'Method baz args ok');

