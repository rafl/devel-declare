use strict;
use warnings;
use Test::More tests => 5;

# This test script is derived from a MooseX::Method::Signatures test,
# which is sensitive to some details of Devel::Declare behaviour that
# ctx-simple.t is not.  In particular, the use of a paren immediately
# following the declarator, constructing a parenthesised function call,
# invokes a different parser path.

use Devel::Declare ();
use Devel::Declare::Context::Simple ();
use B::Hooks::EndOfScope qw(on_scope_end);

sub inject_after_scope($) {
    my ($inject) = @_;
    on_scope_end {
        my $line = Devel::Declare::get_linestr();
        return unless defined $line;
        my $offset = Devel::Declare::get_linestr_offset();
        substr($line, $offset, 0) = $inject;
        Devel::Declare::set_linestr($line);
    };
}

sub mtfnpy_parser(@) {
    my $ctx = Devel::Declare::Context::Simple->new(into => __PACKAGE__);
    $ctx->init(@_);
    $ctx->skip_declarator;
    my $name   = $ctx->strip_name;
    die "No name\n" unless defined $name;
    my $proto  = $ctx->strip_proto;
    die "Wrong declarator\n" unless $ctx->declarator eq "mtfnpy";
    $ctx->inject_if_block(qq[BEGIN { @{[__PACKAGE__]}::inject_after_scope(', q[${name}]);') } unshift \@_, "${proto}";], "(sub ");
    my $compile_stash = $ctx->get_curstash_name;
    $ctx->shadow(sub {
        my ($code, $name, @args) = @_;
        no strict "refs";
        *{"${compile_stash}::${name}"} = $code;
    });
}

BEGIN {
    Devel::Declare->setup_for(__PACKAGE__, {
        mtfnpy => { const => \&mtfnpy_parser },
    });
    *mtfnpy = sub {};
}

mtfnpy foo (extra) {
    is scalar(@_), 4;
    is $_[0], "extra";
    is $_[1], "a";
    is $_[2], "b";
    is $_[3], "c";
}

foo(qw(a b c));

1;
