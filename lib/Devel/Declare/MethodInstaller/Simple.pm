package Devel::Declare::MethodInstaller::Simple;

use base 'Devel::Declare::Context::Simple';

use Devel::Declare ();
use Sub::Name;
use strict;
use warnings;

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

sub parser {
  my $self = shift;
  $self->init(@_);

  $self->skip_declarator;
  my $name   = $self->strip_name;
  my $proto  = $self->strip_proto;
  my @decl   = $self->parse_proto($proto);
  my $inject = $self->inject_parsed_proto(@decl);
  if (defined $name) {
    $inject = $self->scope_injector_call() . $inject;
  }
  $self->inject_if_block($inject);
  if (defined $name) {
    my $pkg = $self->get_curstash_name;
    $name = join( '::', $pkg, $name )
      unless( $name =~ /::/ );
    $self->shadow( sub (&) {
      my $code = shift;
      # So caller() gets the subroutine name
      no strict 'refs';
      *{$name} = subname $name => $code;
    });
  } else {
    $self->shadow(sub (&) { shift });
  }
}

sub parse_proto { }

sub inject_parsed_proto {
  return $_[1];
}

1;

