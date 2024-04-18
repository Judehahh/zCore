const app = @import("app");
const lib = @import("lib");

export fn _start() linksection(".text.entry") callconv(.C) noreturn {
    clearBss();
    lib.exit(callMain());
}

const bad_main_ret = "expected return type of main to be 'void', '!void', 'noreturn', 'u8', or '!u8'";

inline fn callMain() u8 {
    switch (@typeInfo(@typeInfo(@TypeOf(app.main)).Fn.return_type.?)) {
        .NoReturn => {
            app.main();
        },
        .Void => {
            app.main();
            return 0;
        },
        .Int => |info| {
            if (info.bits != 8 or info.signedness == .signed) {
                @compileError(bad_main_ret);
            }
            return app.main();
        },
        .ErrorUnion => {
            const result = app.main() catch |err| {
                lib.console.print("error: {s}\n", .{@errorName(err)});
                return 1;
            };
            switch (@typeInfo(@TypeOf(result))) {
                .Void => return 0,
                .Int => |info| {
                    if (info.bits != 8 or info.signedness == .signed) {
                        @compileError(bad_main_ret);
                    }
                    return result;
                },
                else => @compileError(bad_main_ret),
            }
        },
        else => @compileError(bad_main_ret),
    }
}

fn clearBss() void {
    const start_bss = @extern([*]u8, .{ .name = "start_bss" });
    const end_bss = @extern([*]u8, .{ .name = "end_bss" });
    const bss_len = @intFromPtr(end_bss) - @intFromPtr(start_bss);

    @memset(start_bss[0..bss_len], 0);
}
