pub const console = @import("console.zig");
pub const syscall = @import("syscall.zig");

extern fn main() i32;

export fn _start() linksection(".text.entry") callconv(.C) noreturn {
    clearBss();
    exit(main());
}

fn clearBss() void {
    const start_bss = @extern([*]u8, .{ .name = "start_bss" });
    const end_bss = @extern([*]u8, .{ .name = "end_bss" });
    const bss_len = @intFromPtr(start_bss) - @intFromPtr(end_bss);

    @memset(start_bss[0..bss_len], 0);
}

pub fn write(fd: usize, buf: []const u8) usize {
    return syscall.sysWrite(fd, buf);
}

pub fn exit(exit_code: i32) noreturn {
    syscall.sysExit(exit_code);
    unreachable;
}
