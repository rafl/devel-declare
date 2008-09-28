use inc::Module::Install 0.67;

use 5.008001;

name 'Devel-Declare';
all_from 'lib/Devel/Declare.pm';

requires 'Scalar::Util';
build_requires 'Test::More';
build_requires 'Scope::Guard';

postamble(<<'EOM');
$(OBJECT) : stolen_chunk_of_toke.c
EOM

WriteMakefile(
  dist => {
    PREOP => 'pod2text lib/Devel/Declare.pm >$(DISTVNAME)/README'
  }
);
