package Devel::Declare;

use strict;
use warnings;
use 5.008001;

our $VERSION = 0.001000;

# mirrored in Declare.xs as DD_HANDLE_*

use constant DECLARE_NAME => 1;
use constant DECLARE_PROTO => 2;
use constant DECLARE_NONE => 4;
use constant DECLARE_PACKAGE => 8+1; # name implicit

use vars qw(%declarators %declarator_handlers @ISA);
use base qw(DynaLoader);
use Scalar::Util 'set_prototype';

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

my $temp_name;
my $temp_save;

sub init_declare {
  my ($usepack, $use, $inpack, $name, $proto) = @_;
  my ($name_h, $XX_h, $extra_code)
       = $declarator_handlers{$usepack}{$use}->(
           $usepack, $use, $inpack, $name, $proto, defined(wantarray)
         );
  ($temp_name, $temp_save) = ([], []);
  if ($name) {
    $name = "${inpack}::${name}" unless $name =~ /::/;
    push(@$temp_name, $name);
    no strict 'refs';
    push(@$temp_save, \&{$name});
    no warnings 'redefine';
    no warnings 'prototype';
    *{$name} = $name_h;
  }
  if ($XX_h) {
    push(@$temp_name, "${inpack}::X");
    no strict 'refs';
    push(@$temp_save, \&{"${inpack}::X"});
    no warnings 'redefine';
    no warnings 'prototype';
    *{"${inpack}::X"} = $XX_h;
  }
  if (defined wantarray) {
    return $extra_code || '0;';
  } else {
    return;
  }
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
}

sub build_sub_installer {
  my ($class, $pack, $name, $proto) = @_;
  return eval "
    package ${pack};
    my \$body;
    sub ${name} (${proto}) :lvalue {\n"
    .'my $ret = $body->(@_);
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
    my $proto_maker = eval q!
      sub {
        my $body = shift;
        sub (!.$sub_proto.q!) {
          $body->(@_);
        };
      };
    !;
    $installer->(sub :lvalue {
      if (@_) {
        if (ref $_[0] eq 'HASH') {
          shift;
          my $r = $run->(undef, undef, @_);
          return $r;
        } else {
          return $_[1];
        }
      }
      return my $sv;
    });
    $setup_for_args{$name} = [
      $flags,
      sub {
        my ($usepack, $use, $inpack, $name, $proto) = @_;
        my $extra_code = $compile->($name, $proto);
        my $main_handler = $proto_maker->(sub {
          ("DONE", $run->($name, $proto, @_));
        });
        my ($name_h, $XX);
        if (defined $proto) {
          $name_h = sub :lvalue { return my $sv; };
          $XX = $main_handler;
        } elsif (defined $name && length $name) {
          $name_h = $main_handler;
        } else {
          $extra_code ||= '';
          $extra_code = '}, sub {'.$extra_code;
        }
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
