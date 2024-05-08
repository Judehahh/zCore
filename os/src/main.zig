const sbi = @import("sbi.zig");
const console = @import("console.zig");
const log = @import("log.zig");
const loader = @import("loader.zig");
const task = @import("task.zig");
const trap = @import("trap.zig");

pub fn kmain() void {
    console.print("\n[kernel] Hello {s}⚡\n", .{"zCore"});

    trap.init();
    loader.loadApps();
    task.init();
    task.runFirstTask();

    log.panic(@src(), "Unreachable in kmain!", .{});
}

// Import link_app asm.
const link_app = @import("link_app.zig");
comptime {
    _ = link_app;
}
