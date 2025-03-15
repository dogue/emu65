package cpu

import "core:log"
import "../bus"

RESET_VECTOR :: 0xfffc  // contains the low byte of the address from which to start execution
RESET_ACTIVE: bool      // signals that the chip is currently performing the reset routine

// an internal register used to store the current opcode and cycle counter
Instruction_Register :: bit_field u16 {
    counter: u8 | 4,
    reserved: u8 | 4,
    opcode: u8 | 8,
}

// processor status flags
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

// sets the CPU up for the reset routine and provides an initial bus state
init :: proc(cpu: ^Cpu) -> Bus {
    RESET_ACTIVE = true
    return Bus {
        ctrl = {.RW}
    }
}


tick :: proc(cpu: ^Cpu, bus: Bus) -> Bus {
    defer cpu.ir.counter += 1
    bus := bus

    // bypass normal control flow until the reset is complete (7 cycles)
    if RESET_ACTIVE {
        return _reset(cpu, bus)
    }

    // SYNC pin is active, begin executing a new instruction
    if .SYNC in bus.ctrl {
        cpu.ir.counter = 0
        cpu.ir.opcode = bus.data
        bus.ctrl -= {.SYNC}
        log.debugf("Sync : $%2X", bus.data)
    }

    // simple opcode decoding and handing off control to the instruction handlers
    switch cpu.ir.opcode {
    case 0xA5: bus = lda_zero_page(cpu, bus)
    case 0xA9: bus = lda_immediate(cpu, bus)
    case 0xAD: bus = lda_absolute(cpu, bus)
    case 0xB5: bus = lda_zero_page_x(cpu, bus)
    case 0xB9: bus = lda_absolute_y(cpu, bus)
    case 0xBD: bus = lda_absolute_x(cpu, bus)
    }

    // return the modified bus state
    return bus
}

// prepares for the next opcode read
fetch :: #force_inline proc(cpu: ^Cpu, bus: Bus) -> Bus {
    bus := bus
    bus.addr = cpu.pc
    cpu.pc += 1
    bus.ctrl += {.SYNC, .RW}
    log.debugf("Fetch: $%4X", bus.addr)
    return bus
}

// sets or unsets the negative and zero flags
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
