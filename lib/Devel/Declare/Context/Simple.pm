package Devel::Declare::Context::Simple;

use Devel::Declare ();
use B::Hooks::EndOfScope;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {@_}, $class;
}

sub init {
  my $self = shift;
  @{$self}{ qw(Declarator Offset) } = @_;
  return $self;
}

sub offset {
  my $self = shift;
  return $self->{Offset}
}

sub inc_offset {
  my $self = shift;
  $self->{Offset} += shift;
}

sub declarator {
  my $self = shift;
  return $self->{Declarator}
}

sub skip_declarator {
  my $self = shift;
  $self->inc_offset(Devel::Declare::toke_move_past_token($self->offset));
}

sub skipspace {
  my $self = shift;
  $self->inc_offset(Devel::Declare::toke_skipspace($self->offset));
}

sub get_linestr {
  my $self = shift;
  my $line = Devel::Declare::get_linestr();
  return $line;
}

sub set_linestr {
  my $self = shift;
  my ($line) = @_;
  Devel::Declare::set_linestr($line);
}

sub strip_name {
  my $self = shift;
  $self->skipspace;
  if (my $len = Devel::Declare::toke_scan_word( $self->offset, 1 )) {
    my $linestr = $self->get_linestr();
    my $name = substr( $linestr, $self->offset, $len );
    substr( $linestr, $self->offset, $len ) = '';
    $self->set_linestr($linestr);
    return $name;
  }

  $self->skipspace;
  return;
}

sub strip_ident {
  my $self = shift;
  $self->skipspace;
  if (my $len = Devel::Declare::toke_scan_ident( $self->offset )) {
    my $linestr = $self->get_linestr();
    my $ident = substr( $linestr, $self->offset, $len );
    substr( $linestr, $self->offset, $len ) = '';
    $self->set_linestr($linestr);
    return $ident;
  }

  $self->skipspace;
  return;
}

sub strip_proto {
  my $self = shift;
  $self->skipspace;

  my $linestr = $self->get_linestr();
  if (substr($linestr, $self->offset, 1) eq '(') {
    my $length = Devel::Declare::toke_scan_str($self->offset);
    my $proto = Devel::Declare::get_lex_stuff();
    Devel::Declare::clear_lex_stuff();
    if( $length < 0 ) {
      # Need to scan ahead more
      $linestr .= $self->get_linestr();
      $length = rindex($linestr, ")") - $self->offset + 1;
    }
    else {
      $linestr = $self->get_linestr();
    }

    substr($linestr, $self->offset, $length) = '';
    $self->set_linestr($linestr);

    return $proto;
  }
  return;
}

sub get_curstash_name {
  return Devel::Declare::get_curstash_name;
}

sub shadow {
  my $self = shift;
  my $pack = $self->get_curstash_name;
  Devel::Declare::shadow_sub( $pack . '::' . $self->declarator, $_[0] );
}

sub inject_if_block {
  my $self   = shift;
  my $inject = shift;
  my $before = shift || '';

  $self->skipspace;

  my $linestr = $self->get_linestr;
  if (substr($linestr, $self->offset, 1) eq '{') {
    substr($linestr, $self->offset + 1, 0) = $inject;
    substr($linestr, $self->offset, 0) = $before;
    $self->set_linestr($linestr);
    return 1;
  }
  return 0;
}

sub scope_injector_call {
  my $self = shift;
  my $inject = shift || '';
  return ' BEGIN { ' . ref($self) . "->inject_scope('${inject}') }; ";
}

sub inject_scope {
  my $class = shift;
  my $inject = shift;
  on_scope_end {
      my $linestr = Devel::Declare::get_linestr;
      return unless defined $linestr;
      my $offset  = Devel::Declare::get_linestr_offset;
      substr( $linestr, $offset, 0 ) = ';' . $inject;
      Devel::Declare::set_linestr($linestr);
  };
}

1;
# vi:sw=2 ts=2
