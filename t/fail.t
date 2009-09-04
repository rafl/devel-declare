use strict;
use warnings;
use Test::More 'no_plan';

use Devel::Declare::MethodInstaller::Simple;
BEGIN {
    Devel::Declare::MethodInstaller::Simple->install_methodhandler(
        name => 'method',
        into => __PACKAGE__,
    );
}

TODO: {
    local $TODO = 'Method does not throw proper errors for bad parens yet';

    eval 'method main ( { return "foo" }';
    like($@, qr/Prototype\snot\sterminated/, 'Missing end parens');

    eval 'method main ) { return "foo" }';
    like($@, qr/Illegal\sdeclaration\sof\ssubroutine/, 'Missing start parens');
};

TODO: {
    local $TODO = 'method does not disallow invalid sub names';

    eval 'method 1main() { return "foo" }';
    like($@, qr/Illegal\sdeclaration\sof\sanonymous\ssubroutine/, 'starting with a number');

    eval 'method møø() { return "foo" }';
    like($@, qr/Illegal\sdeclaration\sof\ssubroutine\smain\:\:m/, 'with unicode');
};
