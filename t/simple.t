use strict;
use warnings;
use Test::More 'no_plan';

sub method {
  my ($pack, $name, $sub) = @_;
  no strict 'refs';
  *{"${pack}::${name}"} = $sub;
}

use Devel::Declare 'method';

method bar {
  my $str = join(', ', @_);
  is($str, 'main, baz, quux', 'Method args ok');
};

__PACKAGE__->bar(qw(baz quux));
