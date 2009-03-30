package Devel::Declare::MethodInstaller::Simple;

use base 'Devel::Declare::Context::Simple';

use Devel::Declare ();
use Sub::Name;
use strict;
use warnings;

our $VERSION = '0.003005';

sub install_methodhandler {
  my $class = shift;
  my %args  = @_;
  {
    no strict 'refs';
    *{$args{into}.'::'.$args{name}}   = sub (&) {};
  }

  my $ctx = $class->new(%args);
  Devel::Declare->setup_for(
    $args{into},
    { $args{name} => { const => sub { $ctx->parser(@_) } } }
  );
}

sub strip_attrs {
  my $self = shift;
  $self->skipspace;

  my $linestr = Devel::Declare::get_linestr;
  my $attrs   = '';

  if (substr($linestr, $self->offset, 1) eq ':') {
    while (substr($linestr, $self->offset, 1) ne '{') {
      if (substr($linestr, $self->offset, 1) eq ':') {
        substr($linestr, $self->offset, 1) = '';
        Devel::Declare::set_linestr($linestr);

        $attrs .= ':';
      }

      $self->skipspace;
      $linestr = Devel::Declare::get_linestr();

      if (my $len = Devel::Declare::toke_scan_word($self->offset, 0)) {
        my $name = substr($linestr, $self->offset, $len);
        substr($linestr, $self->offset, $len) = '';
        Devel::Declare::set_linestr($linestr);

        $attrs .= " ${name}";

        if (substr($linestr, $self->offset, 1) eq '(') {
          my $length = Devel::Declare::toke_scan_str($self->offset);
          my $arg    = Devel::Declare::get_lex_stuff();
          Devel::Declare::clear_lex_stuff();
          $linestr = Devel::Declare::get_linestr();
          substr($linestr, $self->offset, $length) = '';
          Devel::Declare::set_linestr($linestr);

          $attrs .= "(${arg})";
        }
      }
    }

    $linestr = Devel::Declare::get_linestr();
  }

  return $attrs;
}

sub code_for {
  my ($self, $name) = @_;

  if (defined $name) {
    my $pkg = $self->get_curstash_name;
    $name = join( '::', $pkg, $name )
      unless( $name =~ /::/ );
    return sub (&) {
      my $code = shift;
      # So caller() gets the subroutine name
      no strict 'refs';
      *{$name} = subname $name => $code;
      return;
    };
  } else {
    return sub (&) { shift };
  }
}

sub install {
  my ($self, $name ) = @_;

  $self->shadow( $self->code_for($name) );
}

sub parser {
  my $self = shift;
  $self->init(@_);

  $self->skip_declarator;
  my $name   = $self->strip_name;
  my $proto  = $self->strip_proto;
  my $attrs  = $self->strip_attrs;
  my @decl   = $self->parse_proto($proto);
  my $inject = $self->inject_parsed_proto(@decl);
  if (defined $name) {
    $inject = $self->scope_injector_call() . $inject;
  }
  $self->inject_if_block($inject, $attrs ? "sub ${attrs} " : '');

  $self->install( $name );

  return;
}

sub parse_proto { '' }

sub inject_parsed_proto {
  return $_[1];
}

1;

