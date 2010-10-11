use strict;
use warnings;

use Devel::Declare ();
use Devel::Declare::Context::Simple;
use Test::More tests => 1;

our @RESULTS;

sub defaultQuote($)         { $_[0] }
sub keepBackslashesQuote($) { $_[0] }
sub keepDelimitersQuote($)  { $_[0] }

BEGIN {
    Devel::Declare->setup_for(
        __PACKAGE__, {
            defaultQuote         => { const => \&default_parser },
            keepBackslashesQuote => { const => \&keep_backslashes_parser },
            keepDelimitersQuote  => { const => \&keep_delimiters_parser }
        }
    );
}

sub default_parser {
    parser_common(sub { Devel::Declare::toke_scan_str(shift) }, @_);
}

sub keep_backslashes_parser {
    parser_common(sub { Devel::Declare::toke_scan_str_flags(shift, 1, 0) }, @_);
}

sub keep_delimiters_parser {
    parser_common(sub { Devel::Declare::toke_scan_str_flags(shift, 0, 1) }, @_);
}

sub parser_common {
    my $scanner = shift;
    my $context = Devel::Declare::Context::Simple->new();

    $context->init(@_);
    $context->skip_declarator;
    $context->skipspace;

    my $offset = $context->offset;
    my $length = $scanner->($offset);
    my $quote = Devel::Declare::get_lex_stuff;

    Devel::Declare::clear_lex_stuff;

    push @RESULTS, $quote;
}

defaultQuote 'foo bar baz';
defaultQuote "foo \"bar\" baz";

keepBackslashesQuote 'foo bar baz';
keepBackslashesQuote "foo \"bar\" baz";

keepDelimitersQuote 'foo bar baz';
keepDelimitersQuote "foo \"bar\" baz";

is_deeply(\@RESULTS, [
    q{foo bar baz},
    q{foo "bar" baz},
    q{foo bar baz},
    q{foo \\"bar\\" baz},
    q{'foo bar baz'},
    q{"foo "bar" baz"},
]);
