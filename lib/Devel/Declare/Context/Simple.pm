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
    my $ctx = shift;
    @{$ctx}{ qw(Declarator Offset) } = @_;
    $ctx;
}

sub offset : lvalue { shift->{Offset}; }
sub declarator { shift->{Declarator} }

sub skip_declarator {
    my $ctx = shift;
    $ctx->offset += Devel::Declare::toke_move_past_token( $ctx->offset );
}

sub skipspace {
    my $ctx = shift;
    $ctx->offset += Devel::Declare::toke_skipspace( $ctx->offset );
}

sub strip_name {
    my $ctx = shift;
    $ctx->skipspace;
    if( my $len = Devel::Declare::toke_scan_word( $ctx->offset, 1 ) ) {
        my $linestr = Devel::Declare::get_linestr();
        my $name = substr( $linestr, $ctx->offset, $len );
        substr( $linestr, $ctx->offset, $len ) = '';
        Devel::Declare::set_linestr($linestr);
        return $name;
    }
    return;
}

sub strip_proto {
    my $ctx = shift;
    $ctx->skipspace;

    my $linestr = Devel::Declare::get_linestr();
    if( substr( $linestr, $ctx->offset, 1 ) eq '(' ) {
        my $length = Devel::Declare::toke_scan_str( $ctx->offset );
        my $proto  = Devel::Declare::get_lex_stuff();
        Devel::Declare::clear_lex_stuff();
        $linestr = Devel::Declare::get_linestr();
        substr( $linestr, $ctx->offset, $length ) = '';
        Devel::Declare::set_linestr($linestr);
        return $proto;
    }
    return;
}

sub get_curstash_name {
    return Devel::Declare::get_curstash_name;
}

sub shadow {
    my $ctx  = shift;
    my $pack = $ctx->get_curstash_name;
    Devel::Declare::shadow_sub( $pack . '::' . $ctx->declarator, $_[0] );
}

sub inject_if_block {
    my $ctx    = shift;
    my $inject = shift;
    $ctx->skipspace;
    my $linestr = Devel::Declare::get_linestr;
    if( substr( $linestr, $ctx->offset, 1 ) eq '{' ) {
        substr( $linestr, $ctx->offset + 1, 0 ) = $inject;
        Devel::Declare::set_linestr($linestr);
    }
}

sub scope_injector_call {
    return ' BEGIN { ' . __PACKAGE__ . '::inject_scope }; ';
}

sub inject_scope {
    my $ctx = shift;
    $^H |= 0x120000;
    $^H{DD_METHODHANDLERS} = Scope::Guard->new(
        sub {
            my $linestr = Devel::Declare::get_linestr;
            my $offset  = Devel::Declare::get_linestr_offset;
            substr( $linestr, $offset, 0 ) = ';';
            Devel::Declare::set_linestr($linestr);
        }
    );
}

1;

