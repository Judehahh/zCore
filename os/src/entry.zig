const kmain = @import("main.zig").kmain;

const boot_stack_size: usize = 4096 * 16;
var boot_stack: [boot_stack_size]u8 linksection(".bss.stack") = undefined;

export fn _start() linksection(".text.entry") callconv(.Naked) noreturn {
    const bootStackTop = @intFromPtr(&boot_stack) + boot_stack_size;
    asm volatile ("mv sp, %[eos]"
        :
        : [eos] "r" (bootStackTop),
    );

    asm volatile ("j callKmain");
}

export fn callKmain() noreturn {
    clearBss();
    kmain();
    while (true) {}
}

extern var sbss: u8;
extern var ebss: u8;

fn clearBss() void {
    const bss_start: [*]u8 = @ptrCast(&sbss);
    const bss_end: [*]u8 = @ptrCast(&ebss);
    const bss_len = @intFromPtr(bss_end) - @intFromPtr(bss_start);

    @memset(bss_start[0..bss_len], 0);
}
