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
