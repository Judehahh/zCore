const sbi = @import("sbi.zig");
const console = @import("console.zig");
const log = @import("log.zig");

pub fn kmain() void {
    console.print("\nHello {s}⚡\n", .{"zCore"});

    {
        const stext: usize = @intFromPtr(@extern([*]u8, .{ .name = "stext" }));
        const etext: usize = @intFromPtr(@extern([*]u8, .{ .name = "etext" }));
        const srodata: usize = @intFromPtr(@extern([*]u8, .{ .name = "srodata" }));
        const erodata: usize = @intFromPtr(@extern([*]u8, .{ .name = "erodata" }));
        const sdata: usize = @intFromPtr(@extern([*]u8, .{ .name = "sdata" }));
        const edata: usize = @intFromPtr(@extern([*]u8, .{ .name = "edata" }));
        const boot_stack: usize = @intFromPtr(@extern([*]u8, .{ .name = "boot_stack" }));
        const sbss: usize = @intFromPtr(@extern([*]u8, .{ .name = "sbss" }));
        const ebss: usize = @intFromPtr(@extern([*]u8, .{ .name = "ebss" }));

        log.trace("[kernel] .text   [0x{x:0>8}, 0x{x:0>8})\n", .{ stext, etext });
        log.debug("[kernel] .rodata [0x{x:0>8}, 0x{x:0>8})\n", .{ srodata, erodata });
        log.info("[kernel] .data   [0x{x:0>8}, 0x{x:0>8})\n", .{ sdata, edata });
        log.warn("[kernel] .stack  [0x{x:0>8}, 0x{x:0>8})\n", .{ boot_stack, sbss });
        log.err("[kernel] .bss    [0x{x:0>8}, 0x{x:0>8})\n", .{ sbss, ebss });
    }

    log.panic(@src(), "Shutdown machine!", .{});
    sbi.shutdown();
}
