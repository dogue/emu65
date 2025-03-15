package m6502

import "core:fmt"
import "core:log"
import "cpu"

/*
    This is a basic example of the emulator in practice. Setting opcode values in RAM directly
    isn't very ergonomic or convenient, but it should be easy to follow what's happening.

    I've included some basic logging at the `fetch` and `sync` points during execution.
    Sync happens when the CPU reads the next opcode from memory. This log line will include
    the opcode that was read.
    Fetch happens at the completion of a full instruction and logs the next address to be read.
    These can be enabled by setting DEBUG below to `true`.

    In this simple example, there are no memory-mapped IO devices and I've split the address
    space evenly between RAM and ROM, each being 32KB.

    The `Bus` structure is passed in and out of the CPU, being modified to set the address and data
    buses, as well as a set of control "pins".

    After each CPU tick, if the RW pin is set by the CPU, the current address on the bus is mapped
    to either RAM or ROM and read from, populating the data bus.

    If the RW pin is not set, then the same happens but with a write, ignoring attempted writes
    to the ROM.
*/

DEBUG := false

main :: proc() {
    context.logger = log.create_console_logger(lowest = DEBUG ? .Debug : .Info, opt = {.Level})
    c: cpu.Cpu
    bus := cpu.init(&c)
    ram: [0x8000]u8
    rom: [0x8000]u8
    ram[0] = 0xad
    ram[1] = 0x37
    ram[2] = 0x13
    ram[3] = 0xa9
    ram[4] = 42
    ram[0x1337] = 69

    for _ in 0..<15 {
        bus = cpu.tick(&c, bus)

        if .RW in bus.ctrl { // read
            if bus.addr < 0x8000 {
                bus.data = ram[bus.addr]
            } else {
                bus.data = rom[bus.addr - 0x8000]
            }
        } else { // write
            if bus.addr < 0x8000 {
                ram[bus.addr] = bus.data
            }
        }
    }

    fmt.printfln("%#v", c)
}
