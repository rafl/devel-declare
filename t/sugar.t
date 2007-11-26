use Devel::Declare;

BEGIN {

  Devel::Declare->install_declarator(
    'DeclareTest', 'method', DECLARE_PACKAGE | DECLARE_PROTO,
    sub {
      my ($name, $proto) = @_;
#no warnings 'uninitialized';
#warn "NP: ".join(', ', @_)."\n";
      return 'my $self = shift;' unless defined $proto && $proto ne '@_';
      return 'my ($self'.(length $proto ? ", ${proto}" : "").') = @_;';
    },
    sub {
      my ($name, $proto, $sub, @rest) = @_;
#no warnings 'uninitialized';
#warn "NPS: ".join(', ', @_)."\n";
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
    my $class = ref $self || $self;
    return bless({ @_ }, $class);
  };

  method foo ($foo) {
    return (ref $self).': Foo: '.$foo;
  };

  method upgrade(){ # no spaces to make case pathological
    bless($self, 'DeclareTest2');
  };

  method DeclareTest2::bar () {
    return 'DeclareTest2: bar';
  };

  $test_method1 = method {
    return join(', ', $self->{attr}, $_[1]);
  };

  $test_method2 = method ($what) {
    return join(', ', ref $self, $what);
  };

  #@test_list = method { 1 }, sub { 2 }, method () { 3 }, sub { 4 };

}

use Test::More 'no_plan';

my $o = DeclareTest->new(attr => "value");

isa_ok($o, 'DeclareTest');

is($o->{attr}, 'value', '@_ args ok');

is($o->foo('yay'), 'DeclareTest: Foo: yay', 'method with argument ok');

$o->upgrade;

isa_ok($o, 'DeclareTest2');

is($o->bar, 'DeclareTest2: bar', 'absolute method declaration ok');

is($o->$test_method1('no', 'yes'), 'value, yes', 'anon method with @_ ok');

is($o->$test_method2('this'), 'DeclareTest2, this', 'anon method with proto ok');

#warn map { $_->() } @test_list;
