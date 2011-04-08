package t::early1_x;
use strict;
use warnings;
sub import {
    require Devel::Declare;
    my $caller = caller();
    Devel::Declare->setup_for($caller, {
        class => {
            const => sub {
                my ($kw, $off) = @_;
                $off += Devel::Declare::toke_move_past_token($off);
                $off += Devel::Declare::toke_skipspace($off);
                die unless substr(Devel::Declare::get_linestr(), $off, 1) eq '{';
                my $l = Devel::Declare::get_linestr();
                substr $l, $off + 1, 0, 'pass q[injected];' . (';' x 1000);
                Devel::Declare::set_linestr($l);
                my $class = sub (&) { $_[0]->() };
                no strict 'refs';
                *{ "${caller}::$kw" } = $class;
            },
        },
    });
}

1;
