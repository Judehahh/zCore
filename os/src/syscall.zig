const console = @import("console.zig");
const log = @import("log.zig");
const task = @import("task.zig");
const timer = @import("timer.zig");

const SysCall = enum(usize) {
    write = 64,
    exit = 93,
    yield = 124,
    gettime = 169,
    _,
};

/// handle syscall exception with `id` and other arguments
pub fn syscall(id: SysCall, arg0: usize, arg1: usize, arg2: usize) usize {
    switch (id) {
        .write => return sysWrite(arg0, @ptrFromInt(arg1), arg2),
        .exit => sysExit(@bitCast(@as(u32, @truncate(arg0)))),
        .yield => return sysYield(),
        .gettime => return sysGetTime(),
        else => log.panic(@src(), "Unsupported syscall id: {d}\n", .{id}),
    }
    unreachable;
}

const fd_StdOut: usize = 1;

/// write buf of length `len` to a file with `fd`
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

/// task exits and submit an exit code
fn sysExit(exit_code: i32) void {
    console.print("[kernel] Application exited with code {d}\n", .{exit_code});
    task.exitCurrentAndRunNext();
    log.panic(@src(), "Unreachable in sysExit\n", .{});
}

/// current task gives up resources for other tasks
fn sysYield() usize {
    task.suspendCurrentAndRunNext();
    return 0;
}

/// get time in milliseconds
pub fn sysGetTime() usize {
    return timer.getTimeMs();
}
