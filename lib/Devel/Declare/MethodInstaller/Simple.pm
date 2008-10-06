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

    my $ctx = $class->new( %args );
    Devel::Declare->setup_for(
        $args{into},
        { $args{name} => { const => sub { $ctx->parser(@_) } } }
    );

}

sub parser {
    my $ctx = shift;
    $ctx->init(@_);

    $ctx->skip_declarator;
    my $name   = $ctx->strip_name;
    my $proto  = $ctx->strip_proto;
    my @decl   = $ctx->parse_proto($proto);
    my $inject = $ctx->inject_parsed_proto(@decl);
    if( defined $name ) {
        $inject = $ctx->scope_injector_call() . $inject;
    }
    $ctx->inject_if_block($inject);
    if( defined $name ) {
        my $pkg = $ctx->get_curstash_name;
        $name = join( '::', $pkg, $name )
            unless( $name =~ /::/ );
        $ctx->shadow( sub (&) {
            my $code = shift;
            # So caller() gets the subroutine name
            no strict 'refs';
            *{$name} = subname $name => $code;
        });
    } else {
        $ctx->shadow(sub (&) { shift });
    }
}
sub parse_proto { }
sub inject_parsed_proto {
    my $ctx = shift;
    shift;
}


1;

