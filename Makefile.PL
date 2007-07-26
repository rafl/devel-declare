use inc::Module::Install 0.67;

name 'Devel-Declare';
all_from 'lib/Devel/Declare.pm';

requires 'Scalar::Util';
build_requires 'Test::More';

WriteMakefile(
  dist => {
    PREOP => 'pod2text lib/Devel/Declare.pm >$(DISTVNAME)/README'
  }
);
