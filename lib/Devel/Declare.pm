package Devel::Declare;

use strict;
use warnings;
use 5.008001;

our $VERSION = 0.001000;

# mirrored in Declare.xs as DD_HANDLE_*

use constant DECLARE_NAME => 1;
use constant DECLARE_PROTO => 2;

use vars qw(%declarators %declarator_handlers);
use base qw(DynaLoader);

bootstrap Devel::Declare;

sub import {
  my ($class, %args) = @_;
  my $target = caller;
  if (@_ == 1) { # "use Devel::Declare;"
    no strict 'refs';
    foreach my $name (qw(DECLARE_NAME DECLARE_PROTO)) {
      *{"${target}::${name}"} = *{"${name}"};
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
    } else {
      die "Info for sub ${key} must be [ \$flags, \$sub ] or \$sub";
    }
    $declarators{$target}{$key} = $flags;
    $declarator_handlers{$target}{$key} = $sub;
  }
}

sub teardown_for {
  my ($class, $target) = @_;
  delete $declarators{$target};
  delete $declarator_handlers{$target};
  teardown();
}

my $temp_pack;
my $temp_name;
my $temp_save;

sub init_declare {
  my ($pack, $use, $name, $proto) = @_;
  my ($name_h, $XX_h) = $declarator_handlers{$pack}{$use}->(
                            $pack, $use, $name, $proto
                        );
  ($temp_pack, $temp_name, $temp_save) = ($pack, [], []);
  if ($name) {
    push(@$temp_name, $name);
    no strict 'refs';
    push(@$temp_save, \&{"${pack}::${name}"});
    no warnings 'redefine';
    no warnings 'prototype';
    *{"${pack}::${name}"} = $name_h;
  }
  if ($XX_h) {
    push(@$temp_name, 'X');
    no strict 'refs';
    push(@$temp_save, \&{"${pack}::X"});
    no warnings 'redefine';
    no warnings 'prototype';
    *{"${pack}::X"} = $XX_h;
  }
}

sub done_declare {
  no strict 'refs';
  my $name = pop(@{$temp_name||[]});
  die "done_declare called with no temp_name stack" unless defined($name);
  my $saved = pop(@$temp_save);
  delete ${"${temp_pack}::"}{$name};
  if ($saved) {
    no warnings 'prototype';
    *{"${temp_pack}::${name}"} = $saved;
  }
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
