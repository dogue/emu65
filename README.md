# emu65

This an unfinished (barely started, really) 6502 emulator implemented in Odin.

It borrows heavily from the cycle-stepping architecture of Andre Weissflog's
[chips project](https://github.com/floooh/chips), with some aspects modified
to better utilize Odin's features such as `bit_set` and `bit_field`.
A breakdown of how this is achieved can be found on
[his blog](https://floooh.github.io/2019/12/13/cycle-stepped-6502.html).

One big difference between his project and mine is scope.
He is emulating many chips and full systems.
I am currently implementing a single processor and doing so in a different language.
I am also attempting to make my code easily digestible for anyone who might be new to
the 6502 and wanting to explore how it works.
