use Devel::Declare;

use Devel::Declare::MethodInstaller::Simple;
BEGIN { Devel::Declare::MethodInstaller::Simple->install_methodhandler(name => 'method', into => 'main') };

use Test::More 'no_plan';

TODO: {
    local $TODO='Method does not throw proper errors for bad parens yet';
    eval 'method main ( { return "foo" }';
    like($@,qr/Prototype\snot\sterminated/,'Missing end parens'); 

    eval 'method main ) { return "foo" }';
    like($@,qr/Illegal\sdeclaration\sof\ssubroutine/,'Missing start parens');
};

TODO: {
    local $TODO='method does not throw proper errors for bad parens yet';
    eval 'method 1main() { return "foo" }','Sub starting with a number';
    like($@,qr/Illegal\sdeclaration\sof\sanonymous\ssubroutine/); 

};