use strict;
use warnings;

use Devel::Declare ();
use Devel::Declare::Context::Simple;
use Test::More tests => 10;

our @RESULTS;

sub defaultQuote($)         { $_[0] }
sub defaultsQuote($)        { $_[0] }
sub keepDelimitersQuote($)  { $_[0] }
sub keepEscapesQuote($)     { $_[0] }
sub verbatimQuote($)        { $_[0] }

BEGIN {
    Devel::Declare->setup_for(
        __PACKAGE__, {
            defaultQuote        => { const => \&default_parser },
            defaultsQuote       => { const => \&defaults_parser },
            keepDelimitersQuote => { const => \&keep_delimiters_parser },
            keepEscapesQuote    => { const => \&keep_escapes_parser },
            verbatimQuote       => { const => \&verbatim_parser }
        }
    );
}

sub default_parser {
    parser_common(sub { Devel::Declare::toke_scan_str(shift) }, @_);
}

sub defaults_parser {
    parser_common(sub { Devel::Declare::toke_scan_str(shift, keep_delimiters => 0, keep_escapes => 0) }, @_);
}

sub keep_delimiters_parser {
    parser_common(sub { Devel::Declare::toke_scan_str(shift, keep_delimiters => 1) }, @_);
}

sub keep_escapes_parser {
    parser_common(sub { Devel::Declare::toke_scan_str(shift, keep_escapes => 1) }, @_);
}

sub verbatim_parser {
    parser_common(sub { Devel::Declare::toke_scan_str(shift, keep_delimiters => 1, keep_escapes => 1) }, @_);
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
is(shift(@RESULTS), q{foo bar baz});

defaultQuote "foo \"bar\" baz";
is(shift(@RESULTS), q{foo "bar" baz});

defaultsQuote 'foo bar baz';
is(shift(@RESULTS), q{foo bar baz});

defaultsQuote "foo \"bar\" baz";
is(shift(@RESULTS), q{foo "bar" baz});

keepDelimitersQuote 'foo bar baz';
is(shift(@RESULTS), q{'foo bar baz'});

keepDelimitersQuote "foo \"bar\" baz";
is(shift(@RESULTS), q{"foo "bar" baz"});

keepEscapesQuote 'foo bar baz';
is(shift(@RESULTS), q{foo bar baz});

keepEscapesQuote "foo \"bar\" baz";
is(shift(@RESULTS), q{foo \\"bar\\" baz});

verbatimQuote 'foo bar baz';
is(shift(@RESULTS), q{'foo bar baz'});

verbatimQuote "foo \"bar\" baz";
is(shift(@RESULTS), q{"foo \\"bar\\" baz"});
