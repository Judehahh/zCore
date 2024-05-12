const CLOCK_FREQ = @import("consts.zig").CLOCK_FREQ;
const set_timer = @import("sbi.zig").set_timer;
const Time = @import("riscv.zig").Time;

const TICKS_PER_SEC: usize = 100;
const MSEC_PER_SEC: usize = 1000;

/// read the `time` register
pub fn getTime() usize {
    return Time.read().bits.mask;
}

/// get current time in milliseconds
pub fn getTimeMs() usize {
    return getTime() / (CLOCK_FREQ / MSEC_PER_SEC);
}

/// set the next timer interrupt
pub fn setNextTrigger() void {
    _ = set_timer(getTime() + CLOCK_FREQ / TICKS_PER_SEC);
}
