#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';

my $Have_Devel_BeginLift;
BEGIN {
  # setup_for_cv() introduced in 0.001001
  $Have_Devel_BeginLift = eval q{ use Devel::BeginLift 0.001001; 1 };
}


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

  sub code_for {
    my($self, $name) = @_;

    my $code = $self->SUPER::code_for($name);

    if( defined $name and $Have_Devel_BeginLift ) {
      Devel::BeginLift->setup_for_cv($code);
    }

    return $code;
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

  # Test at_BEGIN
  SKIP: {
      ::skip "Need Devel::BeginLift for compile time methods", 1
        unless $Have_Devel_BeginLift;
      ::can_ok( "DeclareTest", qw(new foo upgrade) );
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

  method leftie($left) : method { $self->{left} ||= $left; $self->{left} };
}


my $o = DeclareTest->new(attr => "value");

isa_ok($o, 'DeclareTest');

is($o->{attr}, 'value', '@_ args ok');

is($o->foo('yay'), 'DeclareTest: Foo: yay', 'method with argument ok');

is($o->main, 'main', 'declaration of package named method ok');

$o->leftie( 'attributes work' );
is($o->leftie, 'attributes work', 'code attributes intact');

$o->upgrade;

isa_ok($o, 'DeclareTest2');

is($o->bar, 'DeclareTest2: bar', 'absolute method declaration ok');

is($o->$test_method1('no', 'yes'), 'value, yes', 'anon method with @_ ok');

is($o->$test_method2('this'), 'DeclareTest2, this', 'anon method with proto ok');

is_deeply([ map { $_->() } @test_list ], [ 1, 2, 3, 4], 'binding ok');

