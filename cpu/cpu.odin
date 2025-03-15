package cpu

import "core:log"
import "../bus"

RESET_VECTOR :: 0xfffc
FETCH :: bus.Control_Pins{.SYNC, .RW}
RESET_ACTIVE: bool

Instruction_Register :: bit_field u16 {
    counter: u8 | 4,
    reserved: u8 | 4,
    opcode: u8 | 8,
}

Status_Register :: bit_set[Status_Bit]
Status_Bit :: enum {
    Carry,
    Zero,
    Interrupt_Disable,
    Decimal_Mode,
    Break,
    Overflow,
    Negative,
}

Cpu :: struct {
    a, x, y, sp: u8,
    pc: u16,
    p: Status_Register,
    ir: Instruction_Register,
    ad: u16, // internal addr buffer
}

init :: proc(cpu: ^Cpu) -> Bus {
    RESET_ACTIVE = true
    return Bus {
        ctrl = {.RW}
    }
}

tick :: proc(cpu: ^Cpu, bus: Bus) -> Bus {
    defer cpu.ir.counter += 1
    bus := bus

    if RESET_ACTIVE {
        return _reset(cpu, bus)
    }

    if .SYNC in bus.ctrl {
        cpu.ir.counter = 0
        cpu.ir.opcode = bus.data
        bus.ctrl -= {.SYNC}
        log.debugf("Sync : $%2X", bus.data)
    }

    switch cpu.ir.opcode {
    case 0xA5: bus = lda_zero_page(cpu, bus)
    case 0xA9: bus = lda_immediate(cpu, bus)
    case 0xAD: bus = lda_absolute(cpu, bus)
    case 0xB5: bus = lda_zero_page_x(cpu, bus)
    case 0xB9: bus = lda_absolute_y(cpu, bus)
    case 0xBD: bus = lda_absolute_x(cpu, bus)
    }

    return bus
}

fetch :: #force_inline proc(cpu: ^Cpu, bus: Bus) -> Bus {
    bus := bus
    bus.addr = cpu.pc
    cpu.pc += 1
    bus.ctrl += {.SYNC, .RW}
    log.debugf("Fetch: $%4X", bus.addr)
    return bus
}

set_nz :: proc(cpu: ^Cpu, value: u8) {
    if value == 0 {
        cpu.p += {.Zero}
    } else {
        cpu.p -= {.Zero}
    }

    if value & 0x80 != 0 {
        cpu.p += {.Negative}
    } else {
        cpu.p -= {.Negative}
    }
}
