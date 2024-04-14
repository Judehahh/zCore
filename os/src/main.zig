const sbi = @import("sbi.zig");
const console = @import("console.zig");
const log = @import("log.zig");

pub fn kmain() void {
    console.print("Hello {s}\n", .{"zCore"});
    log.pr_trace("Hello {s}\n", .{"zCore"});
    log.pr_debug("Hello {s}\n", .{"zCore"});
    log.pr_info("Hello {s}\n", .{"zCore"});
    log.pr_warn("Hello {s}\n", .{"zCore"});
    log.pr_error("Hello {s}\n", .{"zCore"});
    log.panic(@src(), "Shutdown machine!", .{});
    sbi.shutdown();
}
