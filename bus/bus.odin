package bus

Bus :: struct {
    addr: u16,
    data: u8,
    ctrl: Control_Pins,
}

Control_Pins :: bit_set[Control_Pin]
Control_Pin :: enum {
    RDY,    // memory ready
    NMI,    // active low, jumps to ($fffa, $fffb)
    IRQ,    // active low, jumps to ($fffe, $ffff)
    SYNC,   // high when fetching an opcode
    RW,     // low = write, high = read
    PHI_IN, // clock signal in
    PHI_OUT,// clock signal out
    RST,    // active low, when going high, jumps to ($fffc, $fffd)
    SO,     // active low, sets overflow flag
}
