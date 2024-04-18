const console = @import("console.zig");
const log = @import("log.zig");
const batch = @import("batch.zig");

const SysCall = enum(usize) {
    write = 64,
    exit = 93,
    _,
};

pub fn syscall(id: SysCall, arg0: usize, arg1: usize, arg2: usize) usize {
    switch (id) {
        .write => return sysWrite(arg0, @ptrFromInt(arg1), arg2),
        .exit => sysExit(@bitCast(@as(u32, @truncate(arg0)))),
        else => log.panic(@src(), "Unsupported syscall id: {d}\n", .{id}),
    }
    unreachable;
}

const fd_StdOut: usize = 1;
fn sysWrite(fd: usize, buf: [*]const u8, len: usize) usize {
    switch (fd) {
        fd_StdOut => {
            console.print("{s}", .{buf[0..len]});
            return len;
        },
        else => log.panic(@src(), "Unsupported fd in sysWrite!", .{}),
    }
    unreachable;
}

fn sysExit(exit_code: i32) void {
    console.print("[kernel] Application exited with code {d}\n", .{exit_code});
    batch.app_manager.runNextApp();
}
