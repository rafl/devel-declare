use strict;
use warnings;
use Test::More;

BEGIN {
  eval 'use B::Compiling';

  $@ and plan 'skip_all' => $@
      or plan tests => 9;
}

my @lines;


sub handle_fun {
  my $pack = shift;

  push @lines, PL_compiling->line;

  my $offset = Devel::Declare::get_linestr_offset();
  $offset += Devel::Declare::toke_move_past_token($offset);
  my $stripped = Devel::Declare::toke_skipspace($offset);
  my $linestr = Devel::Declare::get_linestr();

  push @lines, PL_compiling->line;
}


use Devel::Declare;
BEGIN {
sub fun(&) {}

Devel::Declare->setup_for(
  __PACKAGE__,
  { fun => { const => \&handle_fun } }
);
}


#line 100
fun
{ };
my $line  = __LINE__;
my $line2 = __LINE__;

# Reset the line number back to what it actually is
#line 48
is(@lines, 4, "4 line numbers recorded");
is $lines[0], 100, "fun 1 starts on line 100";
is $lines[1], 101, "fun 1 stops on line 101";
is $line, 102, "next statement on line 102";
is $line2, 103, "next statement on line 103";


# Try harder
#line 199
0,
fun
{ };
my $line3 = __LINE__;
my $line4 = __LINE__;

# Reset the line number back to what it actually is
#line 65
is $lines[2], 200, "fun 2 starts on line 200";
is $lines[3], 201, "fun 2 stops on line 201";
is $line3, 202, "next statement on line 202";
is $line4, 203, "next statement on line 203";
