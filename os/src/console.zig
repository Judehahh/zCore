const std = @import("std");
const sbi = @import("sbi.zig");

const Self = @This();
const Error = error{};
pub const Writer = std.io.Writer(*Self, Error, write);

fn write(self: *Self, bytes: []const u8) Error!usize {
    _ = self;

    for (bytes) |c| {
        sbi.console_putchar(c);
    }

    return bytes.len;
}

pub fn writer(self: *Self) Writer {
    return Writer{ .context = self };
}

pub fn print(comptime format: []const u8, args: anytype) void {
    var console = Self{};
    console.writer().print(format, args) catch return;
}
