//! Loading user applications into memory
//!
//! For chapter 3, user applications are simply part of the data included in the
//! kernel binary, so we only need to copy them to the space allocated for each
//! app to load them. We also allocate fixed spaces for each task's
//! [`kernel_stack`] and [`user_stack`].

const std = @import("std");
const TrapContext = @import("trap.zig").TrapContext;
const consts = @import("consts.zig");

const KernelStack = struct {
    data: [consts.KERNEL_STACK_SIZE]u8 align(4096),
    const Self = @This();

    fn getSp(self: *Self) usize {
        return @intFromPtr(&self.data[0]) + consts.KERNEL_STACK_SIZE;
    }

    pub fn pushContext(self: *Self, trap_cx: TrapContext) usize {
        const trap_cx_ptr: *TrapContext = @ptrFromInt(self.getSp() - @sizeOf(TrapContext));
        trap_cx_ptr.* = trap_cx;
        return @intFromPtr(trap_cx_ptr);
    }
};

const UserStack = struct {
    data: [consts.USER_STACK_SIZE]u8 align(4096),
    const Self = @This();

    fn getSp(self: *Self) usize {
        return @intFromPtr(&self.data[0]) + consts.USER_STACK_SIZE;
    }
};

var kernel_stack: [consts.MAX_APP_NUM]KernelStack align(4096) = std.mem.zeroes([consts.MAX_APP_NUM]KernelStack);
var user_stack: [consts.MAX_APP_NUM]UserStack align(4096) = std.mem.zeroes([consts.MAX_APP_NUM]UserStack);

/// Get base address of app i.
fn getBaseAddr(app_id: usize) usize {
    return consts.APP_BASE_ADDRESS + app_id * consts.APP_SIZE_LIMIT;
}

/// Get the total number of applications.
pub fn getNumApp() usize {
    return @extern(*volatile usize, .{ .name = "_num_app" }).*;
}

/// Load nth user app at
/// [APP_BASE_ADDRESS + n * APP_SIZE_LIMIT, APP_BASE_ADDRESS + (n+1) * APP_SIZE_LIMIT).
pub fn loadApps() void {
    const num_app_ptr = @extern([*]const usize, .{ .name = "_num_app" });
    const num_app = num_app_ptr[0];
    const console = @import("console.zig");

    const app_start = num_app_ptr[1 .. num_app + 2];

    console.print("[kernel] num_app = {}\n", .{num_app});

    // load apps
    for (0..num_app) |i| {
        console.print("[kernel] app_{d} [0x{x}, 0x{x})\n", .{ i, app_start[i], app_start[i + 1] });
        const base_addr = getBaseAddr(i);

        // clear region
        @memset(@as(*[consts.APP_SIZE_LIMIT]u8, @ptrFromInt(base_addr)), 0);

        // load app from data section to memory
        const src: [*]const u8 = @ptrFromInt(app_start[i]);
        const dst: [*]u8 = @ptrFromInt(base_addr);
        const len = app_start[i + 1] - app_start[i];
        std.mem.copyForwards(u8, dst[0..len], src[0..len]);
    }

    asm volatile ("fence.i");
}

fn getAppSrc() []const u8 {}

/// Get app info with entry and sp and save `TrapContext` in kernel stack.
pub fn initAppCx(app_id: usize) usize {
    return kernel_stack[app_id].pushContext(TrapContext.init(
        getBaseAddr(app_id),
        user_stack[app_id].getSp(),
    ));
}
