package bus

// represents the address and data buses, as well as a set of "control pins"
Bus :: struct {
    addr: u16,
    data: u8,
    ctrl: Control_Pins,
}

Control_Pins :: bit_set[Control_Pin]
Control_Pin :: enum {
    NMI,    // jumps to ($fffa, $fffb)
    IRQ,    // jumps to ($fffe, $ffff)
    SYNC,   // high when fetching an opcode
    RW,     // low = write, high = read
}
