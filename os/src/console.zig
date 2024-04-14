const std = @import("std");
const sbi = @import("sbi.zig");

const Self = @This();
const Error = error{};
pub const Writer = std.io.Writer(*Self, Error, write);
var console = Self{};

fn write(self: *Self, bytes: []const u8) Error!usize {
    _ = self;
    for (bytes) |b| {
        sbi.console_putchar(b);
    }
    return bytes.len;
}

pub fn writer(self: *Self) Writer {
    return Writer{ .context = self };
}

pub fn print(comptime format: []const u8, args: anytype) void {
    console.writer().print(format, args) catch return;
}
