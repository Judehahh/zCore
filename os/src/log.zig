const std = @import("std");
const sbi = @import("sbi.zig");
const console = @import("console.zig");
const log_level = @import("config").Log;

pub const Level = enum(u8) {
    None = 0,
    Error = 1,
    Warn = 2,
    Info = 3,
    Debug = 4,
    Trace = 5,
};

const Color = enum {
    Red,
    Green,
    Blue,
    Gray,
    Yellow,
    Reset,

    inline fn code(self: Color) []const u8 {
        return switch (self) {
            .Red => "\x1B[31m",
            .Green => "\x1B[32m",
            .Blue => "\x1B[34m",
            .Gray => "\x1B[90m",
            .Yellow => "\x1B[93m",
            .Reset => "\x1B[0m",
        };
    }
};

inline fn ansiFmt(comptime fmt: []const u8, comptime color: Color) []const u8 {
    return color.code() ++ fmt ++ Color.Reset.code();
}

pub inline fn err(comptime fmt: []const u8, args: anytype) void {
    if (@intFromEnum(log_level) >= @intFromEnum(Level.Error)) {
        console.print(ansiFmt("[ERROR] ", Color.Red), .{});
        console.print(ansiFmt(fmt, Color.Red), args);
    }
}

pub inline fn warn(comptime fmt: []const u8, args: anytype) void {
    if (@intFromEnum(log_level) >= @intFromEnum(Level.Warn)) {
        console.print(ansiFmt("[ WARN] ", Color.Yellow), .{});
        console.print(ansiFmt(fmt, Color.Yellow), args);
    }
}

pub inline fn info(comptime fmt: []const u8, args: anytype) void {
    if (@intFromEnum(log_level) >= @intFromEnum(Level.Info)) {
        console.print(ansiFmt("[ INFO] ", Color.Blue), .{});
        console.print(ansiFmt(fmt, Color.Blue), args);
    }
}

pub inline fn debug(comptime fmt: []const u8, args: anytype) void {
    if (@intFromEnum(log_level) >= @intFromEnum(Level.Debug)) {
        console.print(ansiFmt("[DEBUG] ", Color.Green), .{});
        console.print(ansiFmt(fmt, Color.Green), args);
    }
}

pub inline fn trace(comptime fmt: []const u8, args: anytype) void {
    if (@intFromEnum(log_level) >= @intFromEnum(Level.Trace)) {
        console.print(ansiFmt("[TRACE] ", Color.Gray), .{});
        console.print(ansiFmt(fmt, Color.Gray), args);
    }
}

pub inline fn panic(comptime src: std.builtin.SourceLocation, comptime fmt: []const u8, args: anytype) void {
    console.print(ansiFmt("[Kernel] Panicked at {s}:{d} ", Color.Red), .{ src.file, src.line });
    console.print(ansiFmt(fmt ++ "\n", Color.Red), args);
    sbi.shutdown();
}
