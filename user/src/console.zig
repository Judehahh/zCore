const std = @import("std");
const lib = @import("lib.zig");

const Self = @This();
const Error = error{};
const Writer = std.io.Writer(*Self, Error, writeStr);
var console = Self{};

const StdOut: usize = 1;

fn writeStr(self: *Self, bytes: []const u8) Error!usize {
    _ = self;
    _ = lib.write(StdOut, bytes);
    return bytes.len;
}

pub fn writer(self: *Self) Writer {
    return Writer{ .context = self };
}

pub fn print(comptime format: []const u8, args: anytype) void {
    console.writer().print(format, args) catch return;
}
