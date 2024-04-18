const kmain = @import("main.zig").kmain;

const boot_stack_size: usize = 4096 * 16;
export var boot_stack: [boot_stack_size]u8 linksection(".bss.stack") = undefined;

export fn _start() linksection(".text.entry") callconv(.Naked) noreturn {
    const boot_stack_top = @intFromPtr(&boot_stack) + boot_stack_size;
    asm volatile ("mv sp, %[eos]"
        :
        : [eos] "r" (boot_stack_top),
    );

    asm volatile ("j callKmain");
}

export fn callKmain() noreturn {
    clearBss();
    kmain();
    while (true) {}
}

fn clearBss() void {
    const sbss = @extern([*]u8, .{ .name = "sbss" });
    const ebss = @extern([*]u8, .{ .name = "ebss" });
    const bss_len = @intFromPtr(ebss) - @intFromPtr(sbss);

    @memset(sbss[0..bss_len], 0);
}
