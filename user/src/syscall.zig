const SysCall = enum(usize) {
    write = 64,
    exit = 93,
};

fn call(id: SysCall, arg0: usize, arg1: usize, arg2: usize) usize {
    return asm volatile ("ecall"
        : [ret] "={x10}" (-> usize),
        : [which] "{x17}" (@intFromEnum(id)),
          [arg0] "{x10}" (arg0),
          [arg1] "{x11}" (arg1),
          [arg2] "{x12}" (arg2),
        : "memory"
    );
}

pub fn sysWrite(fd: usize, buffer: []const u8) usize {
    return call(.write, fd, @intFromPtr(buffer.ptr), buffer.len);
}

pub fn sysExit(status: i32) noreturn {
    _ = call(.exit, @bitCast(@as(isize, status)), 0, 0);
    unreachable;
}
