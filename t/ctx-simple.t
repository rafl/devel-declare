use Devel::Declare ();

{
  package MethodHandlers;

  use strict;
  use warnings;
  use Devel::Declare::Context::Simple;

  # undef  -> my ($self) = shift;
  # ''     -> my ($self) = @_;
  # '$foo' -> my ($self, $foo) = @_;

  sub make_proto_unwrap {
    my ($proto) = @_;
    my $inject = 'my ($self';
    if (defined $proto) {
      $proto =~ s/[\r\n\s]+/ /g;
      $inject .= ", $proto" if length($proto);
      $inject .= ') = @_; ';
    } else {
      $inject .= ') = shift;';
    }
    return $inject;
  }

  sub parser {
    my $ctx = Devel::Declare::Context::Simple->new->init(@_);

    $ctx->skip_declarator;
    my $name = $ctx->strip_name;
    my $proto = $ctx->strip_proto;

    # Check for an 'is' to test strip_name_and_args
    my $word = $ctx->strip_name;
    my $traits;
    if (defined($word) && ($word eq 'is')) {
      $traits = $ctx->strip_names_and_args;
    }

    my $inject = make_proto_unwrap($proto);
    if (defined $name) {
      $inject = $ctx->scope_injector_call().$inject;
    }
    $ctx->inject_if_block($inject);
    if (defined $name) {
      $name = join('::', Devel::Declare::get_curstash_name(), $name)
        unless ($name =~ /::/);
      # for trait testing we're just interested in the trait parse result, not
      # the method body and its injections
      $ctx->shadow(sub (&) {
        no strict 'refs';
        *{$name} = $traits
          ? sub { $traits }
          : shift;
      });
    } else {
      $ctx->shadow(sub (&) { shift });
    }
  }

}

my ($test_method1, $test_method2, @test_list);

{
  package DeclareTest;

  sub method (&);

  BEGIN {
    Devel::Declare->setup_for(
      __PACKAGE__,
      { method => { const => \&MethodHandlers::parser } }
    );
  }

  method new {
    my $class = ref $self || $self;
    return bless({ @_ }, $class);
  }

  method foo ($foo) {
    return (ref $self).': Foo: '.$foo;
  }

  method has_many_traits() is (Trait1, Trait2(foo => 'bar'), Baz(one, two)) {
    return 1;
  }

  method has_a_trait() is Foo1 {
    return 1;
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

  method multiline1(
  $foo
  )
  {
    return "$foo$foo";
  }

  method multiline2(
    $foo, $bar
  ) { return "$foo $bar"; }

  method 
    multiline3 ($foo,
        $bar) {
    return "$bar $foo";
  }

}

use Test::More 'no_plan';

my $o = DeclareTest->new(attr => "value");

isa_ok($o, 'DeclareTest');

is($o->{attr}, 'value', '@_ args ok');

is($o->foo('yay'), 'DeclareTest: Foo: yay', 'method with argument ok');

is($o->main, 'main', 'declaration of package named method ok');

is($o->multiline1(3), '33', 'multiline1 proto ok');
is($o->multiline2(1,2), '1 2', 'multiline2 proto ok');
is($o->multiline3(4,5), '5 4', 'multiline3 proto ok');

is_deeply(
  $o->has_many_traits,
  [['Trait1', undef], ['Trait2', q[foo => 'bar']], ['Baz', 'one, two']],
  'extracting multiple traits',
);

is_deeply(
  $o->has_a_trait,
  [['Foo1', undef]],
  'extract one trait without arguments',
);

$o->upgrade;

isa_ok($o, 'DeclareTest2');

is($o->bar, 'DeclareTest2: bar', 'absolute method declaration ok');

is($o->$test_method1('no', 'yes'), 'value, yes', 'anon method with @_ ok');

is($o->$test_method2('this'), 'DeclareTest2, this', 'anon method with proto ok');

is_deeply([ map { $_->() } @test_list ], [ 1, 2, 3, 4], 'binding ok');

