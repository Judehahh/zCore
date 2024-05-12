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

fn call(which: eid, arg0: usize, arg1: usize, arg2: usize) usize {
    return asm volatile ("ecall"
        : [ret] "={x10}" (-> usize),
        : [which] "{x17}" (@intFromEnum(which)),
          [arg0] "{x10}" (arg0),
          [arg1] "{x11}" (arg1),
          [arg2] "{x12}" (arg2),
        : "memory"
    );
}

/// use sbi call to set timer
pub fn set_timer(stime_value: usize) usize {
    return call(.set_timer, stime_value, 0, 0);
}

/// use sbi call to putchar in console
pub fn console_putchar(c: usize) void {
    _ = call(.console_putchar, c, 0, 0);
}

/// use sbi call to getchar from console
pub fn console_getchar() usize {
    return call(.console_getchar, 0, 0, 0);
}

/// use sbi call to shutdown the kernel
pub fn shutdown() void {
    _ = call(.shutdown, 0, 0, 0);
    unreachable;
}
