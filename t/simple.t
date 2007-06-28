use strict;
use warnings;

print "1..1\n";

sub method {
  my ($pack, $name, $sub) = @_;
  no strict 'refs';
  *{"${pack}::${name}"} = $sub;
}

use Devel::Declare 'method';

method bar {
  my $str = join(', ', @_);
  if ($str eq 'main, baz, quux') {
    print "ok 1\n";
  } else {
    print "not ok 1\n";
  }
};

__PACKAGE__->bar(qw(baz quux));
