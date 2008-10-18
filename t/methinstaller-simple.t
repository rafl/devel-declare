
{
  package MethodHandlers;

  use strict;
  use warnings;
  use base 'Devel::Declare::MethodInstaller::Simple';

  # undef  -> my ($self) = shift;
  # ''     -> my ($self) = @_;
  # '$foo' -> my ($self, $foo) = @_;

  sub parse_proto {
    my $ctx = shift;
    my ($proto) = @_;
    my $inject = 'my ($self';
    if (defined $proto) {
      $inject .= ", $proto" if length($proto);
      $inject .= ') = @_; ';
    } else {
      $inject .= ') = shift;';
    }
    return $inject;
  }

}

my ($test_method1, $test_method2, @test_list);

{
  package DeclareTest;

  BEGIN { # normally, this'd go in MethodHandlers::import
  MethodHandlers->install_methodhandler(
    name => 'method',
    into => __PACKAGE__,
  );
  }

  method new {
    my $class = ref $self || $self;
    return bless({ @_ }, $class);
  }

  method foo ($foo) {
    return (ref $self).': Foo: '.$foo;
  }

  method upgrade(){ # no spaces to make case pathological
    bless($self, 'DeclareTest2');
  }

  method DeclareTest2::bar () {
    return 'DeclareTest2: bar';
  }

  $test_method1 = method {
    return join(', ', $self->{attr}, $_[1]);
  };

  $test_method2 = method ($what) {
    return join(', ', ref $self, $what);
  };

  method main () { return "main"; }

  @test_list = (method { 1 }, sub { 2 }, method () { 3 }, sub { 4 });

}

use Test::More 'no_plan';

my $o = DeclareTest->new(attr => "value");

isa_ok($o, 'DeclareTest');

is($o->{attr}, 'value', '@_ args ok');

is($o->foo('yay'), 'DeclareTest: Foo: yay', 'method with argument ok');

is($o->main, 'main', 'declaration of package named method ok');

$o->upgrade;

isa_ok($o, 'DeclareTest2');

is($o->bar, 'DeclareTest2: bar', 'absolute method declaration ok');

is($o->$test_method1('no', 'yes'), 'value, yes', 'anon method with @_ ok');

is($o->$test_method2('this'), 'DeclareTest2, this', 'anon method with proto ok');

is_deeply([ map { $_->() } @test_list ], [ 1, 2, 3, 4], 'binding ok');

__END__
/home/rhesa/perl/t/methinstaller-simple....
ok 1 - The object isa DeclareTest
ok 2 - @_ args ok
ok 3 - method with argument ok
ok 4 - declaration of package named method ok
ok 5 - The object isa DeclareTest2
ok 6 - absolute method declaration ok
ok 7 - anon method with @_ ok
ok 8 - anon method with proto ok
ok 9 - binding ok
1..9
ok
All tests successful.
Files=1, Tests=9,  0 wallclock secs ( 0.04 usr  0.00 sys +  0.05 cusr  0.00 csys =  0.09 CPU)
Result: PASS
