const std = @import("std");
const console = @import("console.zig");
const sbi = @import("sbi.zig");
const TrapContext = @import("trap.zig").TrapContext;

const user_stack_size: usize = 4096 * 2;
const kernel_stack_size: usize = 4096 * 2;
const max_app_num: usize = 16;
const app_base_address: usize = 0x80400000;
const app_size_limit: usize = 0x20000;

const kernel_stack: struct {
    data: [kernel_stack_size]u8 align(4096),
    const Self = @This();

    pub fn getSp(self: Self) usize {
        return @intFromPtr(&self.data[0]) + kernel_stack_size;
    }

    pub fn pushContext(self: Self, cx: TrapContext) *TrapContext {
        const cx_ptr: *TrapContext = @ptrFromInt(self.getSp() - @sizeOf(TrapContext));
        cx_ptr.* = cx;
        return cx_ptr;
    }
} align(4096) = .{ .data = [_]u8{0} ** kernel_stack_size };

var user_stack: struct {
    data: [user_stack_size]u8 align(4096),
    const Self = @This();

    pub fn getSp(self: *Self) usize {
        return @intFromPtr(&self.data[0]) + user_stack_size;
    }
} align(4096) = .{ .data = [_]u8{0} ** user_stack_size };

pub var app_manager: AppManager = undefined;

pub fn init() void {
    app_manager = AppManager.init();
    app_manager.printAppInfo();
}

extern fn __restore(usize) callconv(.C) noreturn;

pub const AppManager = struct {
    num_app: usize,
    current_app: usize,
    app_start: [max_app_num + 1]usize,
    const Self = @This();

    pub fn init() Self {
        const num_app_ptr = @extern([*]const usize, .{ .name = "_num_app" });
        const num_app = num_app_ptr[0];
        var app_start = std.mem.zeroes([max_app_num + 1]usize);
        const app_start_raw = num_app_ptr[1 .. num_app + 2];
        std.mem.copyForwards(usize, &app_start, app_start_raw);
        return .{
            .num_app = num_app,
            .current_app = 0,
            .app_start = app_start,
        };
    }

    pub fn printAppInfo(self: *Self) void {
        console.print("[kernel] num_app = {}\n", .{self.num_app});

        for (0..self.num_app) |i| {
            console.print("[kernel] app_{d} [0x{x}, 0x{x})\n", .{ i, self.app_start[i], self.app_start[i + 1] });
        }
    }

    pub fn runNextApp(self: *Self) void {
        const current_app = self.get_current_app();
        self.loadApp(current_app);
        self.move_to_next_app();
        __restore(@intFromPtr(kernel_stack.pushContext(TrapContext.init(
            app_base_address,
            user_stack.getSp(),
        ))));
    }

    fn loadApp(self: *Self, app_id: usize) void {
        if (app_id >= self.num_app) {
            console.print("[kernel] All applications completed!\n", .{});
            sbi.shutdown();
        }
        console.print("[kernel] Loading app_{}\n", .{app_id});
        // Clear app area.
        const app_area: *[app_size_limit]u8 = @ptrFromInt(app_base_address);
        @memset(app_area, 0);

        // Copy app from source.
        const app_src: [*]u8 = @ptrFromInt(self.app_start[app_id]);
        const app_size: usize = self.app_start[app_id + 1] - self.app_start[app_id];
        std.mem.copyForwards(u8, app_area[0..app_size], app_src[0..app_size]);

        asm volatile ("fence.i");
    }

    fn get_current_app(self: *Self) usize {
        return self.current_app;
    }

    fn move_to_next_app(self: *Self) void {
        self.current_app += 1;
    }
};
