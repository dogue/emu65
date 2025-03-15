package cpu

import "core:log"

// reset routine
_reset :: proc(cpu: ^Cpu, bus: Bus) -> Bus {
    bus := bus

    switch cpu.ir.counter {
    case 0:
        bus.addr = 0x00ff

    case 1:
        bus.addr = 0x0100
        cpu.sp -= 1

    case 2:
        cpu.sp -= 1

    case 3:
        bus.addr = RESET_VECTOR
        cpu.sp -= 1

    case 4:
        cpu.pc = u16(bus.data)
        bus.addr += 1

    case 5:
        cpu.pc |= u16(bus.data) << 8

    case 6:
        RESET_ACTIVE = false
        bus = fetch(cpu, bus)
    }

    return bus
}

/*
    Load accumulator, indexed indirect
    LDA (zp,X)
    0xA1
*/
lda_indexed_indirect :: proc(cpu: ^Cpu, bus: Bus) -> Bus {
    bus := bus

    switch cpu.ir.counter {
    case 0: // set the addr bus to read the zero page address from the next byte
        bus.addr = cpu.pc
        cpu.pc += 1

    case 1: // set the addr bus to the zero page address byte from the instruction
        bus.addr = u16(bus.data)

    case 2: // add the X register to the current address, wrapping to stay within the zero page
        addr := u8(bus.addr) + cpu.x
        bus.addr = u16(addr)

    case 3: // read the low byte of the target address and increment the address bus
        cpu.ad = u16(bus.data)
        bus.addr += 1

    case 4: // read the high byte of the target address
        bus.addr =  u16(bus.data) << 8 | cpu.ad

    case 5: // read from the target address and store in the accumulator
        cpu.a = bus.data
        set_nz(cpu, cpu.a)
        bus = fetch(cpu, bus)
    }

    return bus
}

/*
    Load X register, immediate value
    LDX #
    0xA2
*/
ldx_immediate :: proc(cpu: ^Cpu, bus: Bus) -> Bus {
    bus := bus

    switch cpu.ir.counter {
    case 0:
        bus.addr = cpu.pc
        cpu.pc += 1

    case 1:
        cpu.x = bus.data
        set_nz(cpu, cpu.x)
        bus = fetch(cpu, bus)
    }

    return bus
}

/*
    Load accumulator, zero page
    LDA zp
    0xA5
*/
lda_zero_page :: proc(cpu: ^Cpu, bus: Bus) -> Bus {
    bus := bus

    switch cpu.ir.counter {
    case 0:
        bus.addr = cpu.pc
        cpu.pc += 1

    case 1:
        bus.addr = 0x0000 | u16(bus.data)

    case 2:
        cpu.a = bus.data
        set_nz(cpu, cpu.a)
        bus = fetch(cpu, bus)
    }

    return bus
}

/*
    Load accumulator, immediate value
    LDA #
    0xA9
*/
lda_immediate :: proc(cpu: ^Cpu, bus: Bus) -> Bus {
    bus := bus

    switch cpu.ir.counter {
    case 0:
        bus.addr = cpu.pc
        cpu.pc += 1

    case 1:
        cpu.a = bus.data
        set_nz(cpu, cpu.a)
        bus = fetch(cpu, bus)
    }

    return bus
}

/*
    Load accumulator, absolute
    LDA abs
    0xAD
*/
lda_absolute :: proc(cpu: ^Cpu, bus: Bus) -> Bus {
    bus := bus

    switch cpu.ir.counter {
    case 0:
        bus.addr = cpu.pc
        cpu.pc += 1

    case 1:
        bus.addr = cpu.pc
        cpu.pc += 1
        cpu.ad = u16(bus.data)

    case 2:
        bus.addr = u16(bus.data) << 8 | cpu.ad

    case 3:
        cpu.a = bus.data
        set_nz(cpu, cpu.a)
        bus = fetch(cpu, bus)

    }

    return bus
}

/*
    Load accumulator, indirect indexed
    LDA (zp),Y
    0xB1
*/
lda_indirect_indexed :: proc(cpu: ^Cpu, bus: Bus) -> Bus {
    bus := bus

    switch cpu.ir.counter {
    case 0: // setup to read ZP offset
        bus.addr = cpu.pc
        cpu.pc += 1

    case 1: // read ZP offset and set address bus
        bus.addr = u16(bus.data)

    case 2: // read low byte
        cpu.ad = u16(bus.data)
        bus.addr += 1

    case 3: // read high byte
        cpu.ad |= u16(bus.data) << 8
        al := u8(cpu.ad) + cpu.y
        ah := u8(cpu.ad >> 8)
        bus.addr = u16(ah << 8) | u16(al)

        if al >= u8(cpu.ad) { // page boundary NOT crossed
            cpu.ir.counter += 1 // skip cycle 4
        }

    case 4: // page boundary crossed
        bus.addr = cpu.ad + u16(cpu.y) // set corrected address

    case 5:
        cpu.a = bus.data
        set_nz(cpu, cpu.a)
        bus = fetch(cpu, bus)
    }

    return bus
}

/*
    Load accumulator, zero page with X offset
    LDA zp,X
    0xB5
*/
lda_zero_page_x :: proc(cpu: ^Cpu, bus: Bus) -> Bus {
    bus := bus

    switch cpu.ir.counter {
    case 0:
        bus.addr = cpu.pc
        cpu.pc += 1

    case 1:
        bus.addr = u16(bus.data)

    case 2:
        addr := u8(bus.addr) + cpu.x
        bus.addr = u16(addr)

    case 3:
        cpu.a = bus.data
        set_nz(cpu, cpu.a)
        bus = fetch(cpu, bus)
    }

    return bus
}

/*
    Load accumulator, absolute with Y offset
    LDA abs,Y
    0xB9
*/
lda_absolute_y :: proc(cpu: ^Cpu, bus: Bus) -> Bus {
    bus := bus

    switch cpu.ir.counter {
    case 0:
        bus.addr = cpu.pc
        cpu.pc += 1

    case 1:
        bus.addr = cpu.pc
        cpu.pc += 1
        cpu.ad = u16(bus.data)

    case 2:
        cpu.ad |= u16(bus.data) << 8
        al := u8(cpu.ad) + cpu.y
        ah := u8(cpu.ad >> 8)

        // intermediate read
        // this address is wrong if a page boundary is crossed
        // but this is corrected in cycle 3 in that case
        bus.addr = u16(ah << 8) | u16(al)

        if al >= u8(cpu.ad) {   // check for overflow indicated page boundary crossing
            cpu.ir.counter += 1 // skip cycle 3
        }

    case 3: // page crossed
        bus.addr = cpu.ad + u16(cpu.y)

    case 4:
        cpu.a = bus.data
        set_nz(cpu, cpu.a)
        bus = fetch(cpu, bus)
    }

    return bus
}

/*
    Load accumulator, absolute with X offset
    LDA abs,X
    0xBD
*/
lda_absolute_x :: proc(cpu: ^Cpu, bus: Bus) -> Bus {
    bus := bus

    switch cpu.ir.counter {
    case 0:
        bus.addr = cpu.pc
        cpu.pc += 1

    case 1:
        bus.addr = cpu.pc
        cpu.pc += 1
        cpu.ad = u16(bus.data)

    case 2:
        cpu.ad |= u16(bus.data) << 8
        al := u8(cpu.ad) + cpu.x
        ah := u8(cpu.ad >> 8)

        // intermediate read
        // this address is wrong if a page boundary is crossed
        // but this is corrected in cycle 3 in that case
        bus.addr = u16(ah << 8) | u16(al)

        if al >= u8(cpu.ad) {   // check for overflow indicated page boundary crossing
            cpu.ir.counter += 1 // skip cycle 3
        }

    case 3: // page crossed
        bus.addr = cpu.ad + u16(cpu.x)

    case 4:
        cpu.a = bus.data
        set_nz(cpu, cpu.a)
        bus = fetch(cpu, bus)
    }

    return bus
}
