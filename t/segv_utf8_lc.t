
use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

use Devel::Declare 'method' => sub{};

sub lowercase {
        lc $_[0];
}

is lowercase("FOO\x{263a}"), "foo\x{263a}";

=pod

This test segfaults for me on rev 4944:

gdb --args perl -I blib/arch -I blib/lib t/segv_utf8_lc.t

#0  0xb7ca9a70 in dd_ck_const () from blib/arch/auto/Devel/Declare/Declare.so
#1  0x0806be8d in Perl_vload_module ()
#2  0x0806bfdc in Perl_load_module ()
#3  0x080fa343 in Perl_swash_init ()
#4  0x080fbb1b in Perl_to_utf8_case ()
#5  0x080fbf97 in Perl_to_utf8_lower ()
#6  0x080bdfb8 in Perl_pp_lc ()
#7  0x080a3e0e in Perl_runops_standard ()
#8  0x080a0420 in perl_run ()
#9  0x080623a5 in main ()


Summary of my perl5 (revision 5 version 10 subversion 0) configuration:
  Platform:
    osname=linux, osvers=2.6.24-19-386, archname=i686-linux
    uname='linux schutz 2.6.24-19-386 #1 wed jun 18 14:09:56 utc 2008 i686 gnulinux '
    config_args='-Dprefix=/opt/perl'
    hint=recommended, useposix=true, d_sigaction=define
    useithreads=undef, usemultiplicity=undef
    useperlio=define, d_sfio=undef, uselargefiles=define, usesocks=undef
    use64bitint=undef, use64bitall=undef, uselongdouble=undef
    usemymalloc=n, bincompat5005=undef
  Compiler:
    cc='cc', ccflags ='-fno-strict-aliasing -pipe -I/usr/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64',
    optimize='-O2',
    cppflags='-fno-strict-aliasing -pipe -I/usr/local/include'
    ccversion='', gccversion='4.2.3 (Ubuntu 4.2.3-2ubuntu7)', gccosandvers=''
    intsize=4, longsize=4, ptrsize=4, doublesize=8, byteorder=1234
    d_longlong=define, longlongsize=8, d_longdbl=define, longdblsize=12
    ivtype='long', ivsize=4, nvtype='double', nvsize=8, Off_t='off_t', lseeksize=8
    alignbytes=4, prototype=define
  Linker and Libraries:
    ld='cc', ldflags =' -L/usr/local/lib'
    libpth=/usr/local/lib /lib /usr/lib
    libs=-lnsl -ldl -lm -lcrypt -lutil -lc
    perllibs=-lnsl -ldl -lm -lcrypt -lutil -lc
    libc=/lib/libc-2.7.so, so=so, useshrplib=false, libperl=libperl.a
    gnulibc_version='2.7'
  Dynamic Linking:
    dlsrc=dl_dlopen.xs, dlext=so, d_dlsymun=undef, ccdlflags='-Wl,-E'
    cccdlflags='-fPIC', lddlflags='-shared -O2 -L/usr/local/lib'


Characteristics of this binary (from libperl):
  Compile-time options: PERL_DONT_CREATE_GVSV PERL_MALLOC_WRAP
                        USE_LARGE_FILES USE_PERLIO
  Built under linux
  Compiled at Jul  4 2008 02:57:13
  %ENV:
    PERL5LIB="/home/rhesa/perl:/home/expman/mod_perl_scripts/cpan:/home/expman/mod_perl_scripts"
  @INC:
    /home/rhesa/perl
    /home/expman/mod_perl_scripts/cpan
    /home/expman/mod_perl_scripts
    /opt/perl/lib/5.10.0/i686-linux
    /opt/perl/lib/5.10.0
    /opt/perl/lib/site_perl/5.10.0/i686-linux
    /opt/perl/lib/site_perl/5.10.0
    .

=cut

