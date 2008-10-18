package Devel::Declare::Context::Simple;

use Devel::Declare ();
use Scope::Guard;
use strict;
use warnings;

sub new {
  my $class = shift;
  bless {@_}, $class;
}

sub init {
  my $self = shift;
  @{$self}{ qw(Declarator Offset) } = @_;
  $self;
}

sub offset : lvalue { shift->{Offset}; }
sub declarator { shift->{Declarator} }

sub skip_declarator {
  my $self = shift;
  $self->offset += Devel::Declare::toke_move_past_token( $self->offset );
}

sub skipspace {
  my $self = shift;
  $self->offset += Devel::Declare::toke_skipspace( $self->offset );
}

sub strip_name {
  my $self = shift;
  $self->skipspace;
  if (my $len = Devel::Declare::toke_scan_word( $self->offset, 1 )) {
    my $linestr = Devel::Declare::get_linestr();
    my $name = substr( $linestr, $self->offset, $len );
    substr( $linestr, $self->offset, $len ) = '';
    Devel::Declare::set_linestr($linestr);
    return $name;
  }
  return;
}

sub strip_proto {
  my $self = shift;
  $self->skipspace;

  my $linestr = Devel::Declare::get_linestr();
  if (substr( $linestr, $self->offset, 1 ) eq '(') {
    my $length = Devel::Declare::toke_scan_str( $self->offset );
    my $proto  = Devel::Declare::get_lex_stuff();
    Devel::Declare::clear_lex_stuff();
    $linestr = Devel::Declare::get_linestr();
    substr( $linestr, $self->offset, $length ) = '';
    Devel::Declare::set_linestr($linestr);
    return $proto;
  }
  return;
}

sub get_curstash_name {
  return Devel::Declare::get_curstash_name;
}

sub shadow {
  my $self  = shift;
  my $pack = $self->get_curstash_name;
  Devel::Declare::shadow_sub( $pack . '::' . $self->declarator, $_[0] );
}

sub inject_if_block {
  my $self    = shift;
  my $inject = shift;
  $self->skipspace;
  my $linestr = Devel::Declare::get_linestr;
  if (substr( $linestr, $self->offset, 1 ) eq '{') {
    substr( $linestr, $self->offset + 1, 0 ) = $inject;
    Devel::Declare::set_linestr($linestr);
  }
}

sub scope_injector_call {
  return ' BEGIN { ' . __PACKAGE__ . '::inject_scope }; ';
}

sub inject_scope {
  my $self = shift;
  $^H |= 0x120000;
  $^H{DD_METHODHANDLERS} = Scope::Guard->new(sub {
      my $linestr = Devel::Declare::get_linestr;
      my $offset  = Devel::Declare::get_linestr_offset;
      substr( $linestr, $offset, 0 ) = ';';
      Devel::Declare::set_linestr($linestr);
  });
}

1;

