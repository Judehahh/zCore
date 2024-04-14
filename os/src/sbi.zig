const eid = enum(usize) {
    set_timer = 0,
    console_putchar = 1,
    console_getchar = 2,
    clear_ipi = 3,
    send_ipi = 4,
    remote_fence_i = 5,
    remote_sfence_vma = 6,
    remote_sfence_vma_asid = 7,
    shutdown = 8,
};

inline fn call(which: eid, arg0: usize, arg1: usize, arg2: usize) usize {
    return asm volatile ("ecall"
        : [ret] "={x10}" (-> usize),
        : [which] "{x17}" (@intFromEnum(which)),
          [arg0] "{x10}" (arg0),
          [arg1] "{x11}" (arg1),
          [arg2] "{x12}" (arg2),
        : "memory"
    );
}

pub fn console_putchar(c: usize) void {
    _ = call(eid.console_putchar, c, 0, 0);
}

pub fn console_getchar() usize {
    return call(eid.console_getchar, 0, 0, 0);
}

pub fn shutdown() void {
    _ = call(eid.shutdown, 0, 0, 0);
    unreachable;
}
