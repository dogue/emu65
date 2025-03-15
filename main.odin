package m6502

import "core:fmt"
import "core:log"
import "cpu"

main :: proc() {
    context.logger = log.create_console_logger(opt = {.Level})
    c: cpu.Cpu
    bus := cpu.init(&c)
    ram: [0x8000]u8
    rom: [0x8000]u8
    ram[0] = 0xad
    ram[1] = 0x37
    ram[2] = 0x13
    ram[3] = 0xa9
    ram[4] = 88
    ram[0x1337] = 69

    for _ in 0..<15 {
        bus = cpu.tick(&c, bus)

        if .RW in bus.ctrl { // read
            log.debugf("Read : $%4X", bus.addr)
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
