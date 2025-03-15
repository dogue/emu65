package cpu

import "core:testing"

@(test)
test_lda_immediate :: proc(t: ^testing.T) {
    c: Cpu
    b := init(&c)
    b.data = 0xA9

    b = tick(&c, b)
}
