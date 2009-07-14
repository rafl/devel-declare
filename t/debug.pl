use strict;
use warnings;

use Devel::Declare;

BEGIN {

  Devel::Declare->install_declarator(
    'DeclareTest', 'method', DECLARE_PACKAGE | DECLARE_PROTO,
    sub {
      my ($name, $proto) = @_;
      return 'my $self = shift;' unless defined $proto && $proto ne '@_';
      return 'my ($self'.(length $proto ? ", ${proto}" : "").') = @_;';
    },
    sub {
      my ($name, $proto, $sub, @rest) = @_;
      if (defined $name && length $name) {
        unless ($name =~ /::/) {
          $name = "DeclareTest::${name}";
        }
        no strict 'refs';
        *{$name} = $sub;
      }
      return wantarray ? ($sub, @rest) : $sub;
    }
  );

}

my ($test_method1, $test_method2, @test_list);

{
  package DeclareTest;

  method new {
  };

}

{ no strict;
  no warnings 'uninitialized';
  print @{"_<t/debug.pl"};
}
