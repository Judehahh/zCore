pub const console = @import("console.zig");
pub const syscall = @import("syscall.zig");

pub const print = console.print;

pub fn write(fd: usize, buf: []const u8) usize {
    return syscall.sysWrite(fd, buf);
}

pub fn exit(exit_code: i32) noreturn {
    syscall.sysExit(exit_code);
    unreachable;
}

pub fn yield_() usize {
    return syscall.sysYield();
}
