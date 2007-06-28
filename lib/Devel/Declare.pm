package Devel::Declare;

use strict;
use warnings;
use 5.008001;

our $VERSION = 0.001000;

use vars qw(%declarators);
use base qw(DynaLoader);

bootstrap Devel::Declare;

sub import {
  my ($class, @args) = @_;
  my $target = caller;
  $class->setup_for($target => \@args);
}

sub unimport {
  my ($class) = @_;
  my $target = caller;
  $class->teardown_for($target);
}

sub setup_for {
  my ($class, $target, $args) = @_;
  setup();
  $declarators{$target}{$_} = 1 for @$args;
}

sub teardown_for {
  my ($class, $target) = @_;
  delete $declarators{$target};
  teardown();
}

my $temp_pack;
my $temp_name;

sub init_declare {
  my ($pack, $use, $name) = @_;
  no strict 'refs';
  *{"${pack}::${name}"} = sub (&) { ($pack, $name, $_[0]); };
  ($temp_pack, $temp_name) = ($pack, $name);
}

sub done_declare {
  no strict 'refs';
  delete ${"${temp_pack}::"}{$temp_name};
}

=head1 NAME

Devel::Declare - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 import

  use Devel::Declare qw(list of subs);

Calls Devel::Declare->setup_for(__PACKAGE__ => \@list_of_subs);

=head2 unimport

  no Devel::Declare;

Calls Devel::Declare->teardown_for(__PACKAGE__);

=head2 setup_for

  Devel::Declare->setup_for($package => \@subnames);

Installs declarator magic (unless already installed) and registers
"${package}::$name" for each member of @subnames

=head2 teardown_for

  Devel::Declare->teardown_for($package);

Deregisters all subs currently registered for $package and uninstalls
declarator magic if number of teardown_for calls matches number of setup_for
calls.

=head1 AUTHOR

Matt S Trout - <mst@shadowcatsystems.co.uk>

Company: http://www.shadowcatsystems.co.uk/
Blog: http://chainsawblues.vox.com/

=head1 LICENSE

This library is free software under the same terms as perl itself

=cut

1;
