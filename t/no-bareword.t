use strict;
use warnings;
use Test::More;

our $i;
BEGIN { $i = 0 };

sub method { }
BEGIN {
        require Devel::Declare;
        Devel::Declare->setup_for(
                __PACKAGE__,
                { "method" => { const => sub { $i++ } } },
        );
}

{
    package Foo;
    sub method { }
}

Foo->method;
BEGIN { is($i, 0) }

my @foo = (
    method
    =>
    123
);

TODO: {
    BEGIN {
        local $TODO = 'fat commas not quoting barewords';
        is($i, 0);
    }
}

done_testing;
