use inc::Module::Install 0.67;

use 5.008001;

name 'Devel-Declare';
version '0.001008';
all_from 'lib/Devel/Declare.pm';

requires 'Scalar::Util';
build_requires 'Test::More';

WriteMakefile(
  dist => {
    PREOP => 'pod2text lib/Devel/Declare.pm >$(DISTVNAME)/README'
  }
);
