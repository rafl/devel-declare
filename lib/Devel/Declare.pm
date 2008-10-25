package Devel::Declare;

use strict;
use warnings;
use 5.008001;

our $VERSION = '0.003001';

use constant DECLARE_NAME => 1;
use constant DECLARE_PROTO => 2;
use constant DECLARE_NONE => 4;
use constant DECLARE_PACKAGE => 8+1; # name implicit

use vars qw(%declarators %declarator_handlers @ISA);
use base qw(DynaLoader);
use Scalar::Util 'set_prototype';
use B::Hooks::OP::Check;

bootstrap Devel::Declare;

@ISA = ();

sub import {
  my ($class, %args) = @_;
  my $target = caller;
  if (@_ == 1) { # "use Devel::Declare;"
    no strict 'refs';
    foreach my $name (qw(NAME PROTO NONE PACKAGE)) {
      *{"${target}::DECLARE_${name}"} = *{"DECLARE_${name}"};
    }
  } else {
    $class->setup_for($target => \%args);
  }
}

sub unimport {
  my ($class) = @_;
  my $target = caller;
  $class->teardown_for($target);
}

sub setup_for {
  my ($class, $target, $args) = @_;
  setup();
  foreach my $key (keys %$args) {
    my $info = $args->{$key};
    my ($flags, $sub);
    if (ref($info) eq 'ARRAY') {
      ($flags, $sub) = @$info;
    } elsif (ref($info) eq 'CODE') {
      $flags = DECLARE_NAME;
      $sub = $info;
    } elsif (ref($info) eq 'HASH') {
      $flags = 1;
      $sub = $info;
    } else {
      die "Info for sub ${key} must be [ \$flags, \$sub ] or \$sub or handler hashref";
    }
    $declarators{$target}{$key} = $flags;
    $declarator_handlers{$target}{$key} = $sub;
  }
}

sub teardown_for {
  my ($class, $target) = @_;
  delete $declarators{$target};
  delete $declarator_handlers{$target};
}

my $temp_name;
my $temp_save;

sub init_declare {
  my ($usepack, $use, $inpack, $name, $proto, $traits) = @_;
  my ($name_h, $XX_h, $extra_code)
       = $declarator_handlers{$usepack}{$use}->(
           $usepack, $use, $inpack, $name, $proto, defined(wantarray), $traits
         );
  ($temp_name, $temp_save) = ([], []);
  if ($name) {
    $name = "${inpack}::${name}" unless $name =~ /::/;
    shadow_sub($name, $name_h);
  }
  if ($XX_h) {
    shadow_sub("${inpack}::X", $XX_h);
  }
  if (defined wantarray) {
    return $extra_code || '0;';
  } else {
    return;
  }
}

sub shadow_sub {
  my ($name, $cr) = @_;
  push(@$temp_name, $name);
  no strict 'refs';
  my ($pack, $pname) = ($name =~ m/(.+)::([^:]+)/);
  push(@$temp_save, $pack->can($pname));
  no warnings 'redefine';
  no warnings 'prototype';
  *{$name} = $cr;
  set_in_declare(~~@{$temp_name||[]});
}

sub done_declare {
  no strict 'refs';
  my $name = shift(@{$temp_name||[]});
  die "done_declare called with no temp_name stack" unless defined($name);
  my $saved = shift(@$temp_save);
  $name =~ s/(.*):://;
  my $temp_pack = $1;
  delete ${"${temp_pack}::"}{$name};
  if ($saved) {
    no warnings 'prototype';
    *{"${temp_pack}::${name}"} = $saved;
  }
  set_in_declare(~~@{$temp_name||[]});
}

sub build_sub_installer {
  my ($class, $pack, $name, $proto) = @_;
  return eval "
    package ${pack};
    my \$body;
    sub ${name} (${proto}) :lvalue {\n"
    .'  if (wantarray) {
        goto &$body;
      }
      my $ret = $body->(@_);
      return $ret;
    };
    sub { ($body) = @_; };';
}

sub setup_declarators {
  my ($class, $pack, $to_setup) = @_;
  die "${class}->setup_declarators(\$pack, \\\%to_setup)"
    unless defined($pack) && ref($to_setup) eq 'HASH';
  my %setup_for_args;
  foreach my $name (keys %$to_setup) {
    my $info = $to_setup->{$name};
    my $flags = $info->{flags} || DECLARE_NAME;
    my $run = $info->{run};
    my $compile = $info->{compile};
    my $proto = $info->{proto} || '&';
    my $sub_proto = $proto;
    # make all args optional to enable lvalue for DECLARE_NONE
    $sub_proto =~ s/;//; $sub_proto = ';'.$sub_proto;
    #my $installer = $class->build_sub_installer($pack, $name, $proto);
    my $installer = $class->build_sub_installer($pack, $name, '@');
    $installer->(sub :lvalue {
#{ no warnings 'uninitialized'; warn 'INST: '.join(', ', @_)."\n"; }
      if (@_) {
        if (ref $_[0] eq 'HASH') {
          shift;
          if (wantarray) {
            my @ret = $run->(undef, undef, @_);
            return @ret;
          }
          my $r = $run->(undef, undef, @_);
          return $r;
        } else {
          return @_[1..$#_];
        }
      }
      return my $sv;
    });
    $setup_for_args{$name} = [
      $flags,
      sub {
        my ($usepack, $use, $inpack, $name, $proto, $shift_hashref, $traits) = @_;
        my $extra_code = $compile->($name, $proto, $traits);
        my $main_handler = sub { shift if $shift_hashref;
          ("DONE", $run->($name, $proto, @_));
        };
        my ($name_h, $XX);
        if (defined $proto) {
          $name_h = sub :lvalue { return my $sv; };
          $XX = $main_handler;
        } elsif (defined $name && length $name) {
          $name_h = $main_handler;
        }
        $extra_code ||= '';
        $extra_code = '}, sub {'.$extra_code;
        return ($name_h, $XX, $extra_code);
      }
    ];
  }
  $class->setup_for($pack, \%setup_for_args);
}

sub install_declarator {
  my ($class, $target_pack, $target_name, $flags, $filter, $handler) = @_;
  $class->setup_declarators($target_pack, {
    $target_name => {
      flags => $flags,
      compile => $filter,
      run => $handler,
   }
  });
}

sub linestr_callback_rv2cv {
  my ($name, $offset) = @_;
  $offset += toke_move_past_token($offset);
  my $pack = get_curstash_name();
  my $flags = $declarators{$pack}{$name};
  my ($found_name, $found_proto);
  if ($flags & DECLARE_NAME) {
    $offset += toke_skipspace($offset);
    my $linestr = get_linestr();
    if (substr($linestr, $offset, 2) eq '::') {
      substr($linestr, $offset, 2) = '';
      set_linestr($linestr);
    }
    if (my $len = toke_scan_word($offset, $flags & DECLARE_PACKAGE)) {
      $found_name = substr($linestr, $offset, $len);
      $offset += $len;
    }
  }
  if ($flags & DECLARE_PROTO) {
    $offset += toke_skipspace($offset);
    my $linestr = get_linestr();
    if (substr($linestr, $offset, 1) eq '(') {
      my $length = toke_scan_str($offset);
      $found_proto = get_lex_stuff();
      clear_lex_stuff();
      my $replace =
        ($found_name ? ' ' : '=')
        .'X'.(' ' x length($found_proto));
      $linestr = get_linestr();
      substr($linestr, $offset, $length) = $replace;
      set_linestr($linestr);
      $offset += $length;
    }
  }
  my @args = ($pack, $name, $pack, $found_name, $found_proto);
  $offset += toke_skipspace($offset);
  my $linestr = get_linestr();
  if (substr($linestr, $offset, 1) eq '{') {
    my $ret = init_declare(@args);
    $offset++;
    if (defined $ret && length $ret) {
      substr($linestr, $offset, 0) = $ret;
      set_linestr($linestr);
    }
  } else {
    init_declare(@args);
  }
  #warn "linestr now ${linestr}";
}

sub linestr_callback_const {
  my ($name, $offset) = @_;
  my $pack = get_curstash_name();
  my $flags = $declarators{$pack}{$name};
  if ($flags & DECLARE_NAME) {
    $offset += toke_move_past_token($offset);
    $offset += toke_skipspace($offset);
    if (toke_scan_word($offset, $flags & DECLARE_PACKAGE)) {
      my $linestr = get_linestr();
      substr($linestr, $offset, 0) = '::';
      set_linestr($linestr);
    }
  }
}

sub linestr_callback {
  my $type = shift;
  my $name = $_[0];
  my $pack = get_curstash_name();
  my $handlers = $declarator_handlers{$pack}{$name};
  if (ref $handlers eq 'CODE') {
    my $meth = "linestr_callback_${type}";
    __PACKAGE__->can($meth)->(@_);
  } elsif (ref $handlers eq 'HASH') {
    if ($handlers->{$type}) {
      $handlers->{$type}->(@_);
    }
  } else {
    die "PANIC: unknown thing in handlers for $pack $name: $handlers";
  }
}

=head1 NAME

Devel::Declare - Adding keywords to perl, in perl

=head1 SYNOPSIS

  use Devel::Declare ();
  
  {
    package MethodHandlers;
  
    use strict;
    use warnings;
    use B::Hooks::EndOfScope;
  
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

    sub scope_injector_call {
      return ' BEGIN { MethodHandlers::inject_scope }; ';
    }
  
    sub parser {
      local ($Declarator, $Offset) = @_;
      skip_declarator;
      my $name = strip_name;
      my $proto = strip_proto;
      my $inject = make_proto_unwrap($proto);
      if (defined $name) {
        $inject = scope_injector_call().$inject;
      }
      inject_if_block($inject);
      if (defined $name) {
        $name = join('::', Devel::Declare::get_curstash_name(), $name)
          unless ($name =~ /::/);
        shadow(sub (&) { no strict 'refs'; *{$name} = shift; });
      } else {
        shadow(sub (&) { shift });
      }
    }
  
    sub inject_scope {
      on_scope_end {
        my $linestr = Devel::Declare::get_linestr;
        my $offset = Devel::Declare::get_linestr_offset;
        substr($linestr, $offset, 0) = ';';
        Devel::Declare::set_linestr($linestr);
      };
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

(this is t/method-no-semi.t in this distribution)

=head1 DESCRIPTION

=head2 setup_for

  Devel::Declare->setup_for(
    $package,
    {
      $name => { $op_type => $sub }
    }
  );

Currently valid op types: 'check', 'rv2cv'

=head1 AUTHORS

Matt S Trout - <mst@shadowcat.co.uk>

Company: http://www.shadowcat.co.uk/
Blog: http://chainsawblues.vox.com/

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

=head1 LICENSE

This library is free software under the same terms as perl itself

=cut

1;
