use inc::Module::Install 0.67;

use 5.008001;

use ExtUtils::Depends;

name 'Devel-Declare';
all_from 'lib/Devel/Declare.pm';

requires 'Scalar::Util';
requires 'B::Hooks::OP::Check' => '0.10';
requires 'B::Hooks::Parser';
build_requires 'B::Hooks::OP::Check' => '0.10';
build_requires 'B::Hooks::Parser';
configure_requires 'ExtUtils::Depends';
configure_requires 'B::Hooks::OP::Check' => '0.10';
configure_requires 'B::Hooks::Parser';
test_requires 'Test::More';
test_requires 'B::Hooks::EndOfScope';

postamble(<<'EOM');
$(OBJECT) : stolen_chunk_of_toke.c
EOM

my $pkg = ExtUtils::Depends->new('Devel::Declare', 'B::Hooks::OP::Check', 'B::Hooks::Parser');

WriteMakefile(
  dist => {
    PREOP => 'pod2text lib/Devel/Declare.pm >$(DISTVNAME)/README'
  },
  $pkg->get_makefile_vars,
);
