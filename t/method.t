use Devel::Declare ();

{
  package MethodHandlers;

  use strict;
  use warnings;

  our ($Declarator, $Offset);

  sub skip_declarator {
    $Offset += Devel::Declare::toke_move_past_token($Offset);
  }

  sub skipspace {
    $Offset += Devel::Declare::toke_skipspace($Offset);
  }

  sub strip_name {
    skipspace;
    if (my $len = Devel::Declare::toke_scan_word($Offset, 1)) {
      my $linestr = Devel::Declare::get_linestr();
      my $name = substr($linestr, $Offset, $len);
      substr($linestr, $Offset, $len) = '';
      Devel::Declare::set_linestr($linestr);
      return $name;
    }
    return;
  }

  sub strip_proto {
    skipspace;
    
    my $linestr = Devel::Declare::get_linestr();
    if (substr($linestr, $Offset, 1) eq '(') {
      my $length = Devel::Declare::toke_scan_str($Offset);
      my $proto = Devel::Declare::get_lex_stuff();
      Devel::Declare::clear_lex_stuff();
      $linestr = Devel::Declare::get_linestr();
      substr($linestr, $Offset, $length) = '';
      Devel::Declare::set_linestr($linestr);
      return $proto;
    }
    return;
  }

  sub shadow {
    my $pack = Devel::Declare::get_curstash_name;
    Devel::Declare::shadow_sub("${pack}::${Declarator}", $_[0]);
  }

  # undef  -> my ($self) = shift;
  # ''     -> my ($self) = @_;
  # '$foo' -> my ($self, $foo) = @_;

  sub make_proto_unwrap {
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

  sub inject_if_block {
    my $inject = shift;
    skipspace;
    my $linestr = Devel::Declare::get_linestr;
    if (substr($linestr, $Offset, 1) eq '{') {
      substr($linestr, $Offset+1, 0) = $inject;
      Devel::Declare::set_linestr($linestr);
    }
  }

  sub parser {
    local ($Declarator, $Offset) = @_;
    skip_declarator;
    my $name = strip_name;
    my $proto = strip_proto;
    inject_if_block(
      make_proto_unwrap($proto)
    );
    if (defined $name) {
      $name = join('::', Devel::Declare::get_curstash_name(), $name)
        unless ($name =~ /::/);
      shadow(sub (&) { no strict 'refs'; *{$name} = shift; });
    } else {
      shadow(sub (&) { shift });
    }
  }

  sub inject_scope {
    $^H |= 0x120000;
    $^H{DD_METHODHANDLERS} = Scope::Guard->new(sub {
      my $linestr = Devel::Declare::get_linestr;
      my $offset = Devel::Declare::get_linestr_offset;
      substr($linestr, $offset, 0) = ';';
      Devel::Declare::set_linestr($linestr);
    });
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
  };

  method foo (
      $foo
  ) {
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

  method main () { return "main"; };

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
