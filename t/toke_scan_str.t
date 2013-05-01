use strict;
use warnings;

use Devel::Declare ();
use Devel::Declare::Context::Simple;
use Test::More tests => 12;

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

    push @RESULTS, [ $quote, $length ];
}

# note: length is the number of characters in the source code
# e.g. 13 for 'foo bar baz' and 17 for "foo \"bar\" baz"

defaultQuote 'foo bar baz';
is_deeply(shift(@RESULTS), [ q{foo bar baz}, 13 ]);
defaultQuote "foo \"bar\" baz";
is_deeply(shift(@RESULTS), [ q{foo "bar" baz}, 17 ]);

defaultsQuote 'foo bar baz';
is_deeply(shift(@RESULTS), [ q{foo bar baz}, 13 ]);
defaultsQuote "foo \"bar\" baz";
is_deeply(shift(@RESULTS), [ q{foo "bar" baz}, 17 ]);

keepDelimitersQuote 'foo bar baz';
is_deeply(shift(@RESULTS), [ q{'foo bar baz'}, 13 ]);
keepDelimitersQuote "foo \"bar\" baz";
is_deeply(shift(@RESULTS), [ q{"foo "bar" baz"}, 17 ]);

keepEscapesQuote 'foo bar baz';
is_deeply(shift(@RESULTS), [ q{foo bar baz}, 13 ]);
keepEscapesQuote "foo \"bar\" baz";
is_deeply(shift(@RESULTS), [ q{foo \\"bar\\" baz}, 17 ]);

verbatimQuote 'foo bar baz';
is_deeply(shift(@RESULTS), [ q{'foo bar baz'}, 13 ]);
verbatimQuote "foo \"bar\" baz";
is_deeply(shift(@RESULTS), [ q{"foo \\"bar\\" baz"}, 17 ]);

# lex_get_stuff is unreliable on failure - only the length result is documented, so just test that
BEGIN { eval 'defaultQuote q{foo bar baz};'; }
is_deeply(shift(@RESULTS), [ '', -1 ]);

# make sure the example in the documentation is correct
verbatimQuote "\\foo\"";
is_deeply(shift(@RESULTS), [ q{"\\\\foo\\""}, 9 ]);
