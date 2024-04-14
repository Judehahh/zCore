const std = @import("std");
const LogLevel = @import("config").Log;
const sbi = @import("sbi.zig");
const console = @import("console.zig");

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

inline fn ansi_fmt(comptime fmt: []const u8, comptime color: Color) []const u8 {
    return color.code() ++ fmt ++ Color.Reset.code();
}

pub inline fn pr_error(comptime fmt: []const u8, args: anytype) void {
    if (@intFromEnum(LogLevel) >= @intFromEnum(Level.Error)) {
        console.print(ansi_fmt("[ERROR] [kernel]", Color.Red), .{});
        console.print(ansi_fmt(fmt, Color.Red), args);
    }
}

pub inline fn pr_warn(comptime fmt: []const u8, args: anytype) void {
    if (@intFromEnum(LogLevel) >= @intFromEnum(Level.Warn)) {
        console.print(ansi_fmt("[ WARN] [kernel]", Color.Yellow), .{});
        console.print(ansi_fmt(fmt, Color.Yellow), args);
    }
}

pub inline fn pr_info(comptime fmt: []const u8, args: anytype) void {
    if (@intFromEnum(LogLevel) >= @intFromEnum(Level.Info)) {
        console.print(ansi_fmt("[ INFO] [kernel]", Color.Blue), .{});
        console.print(ansi_fmt(fmt, Color.Blue), args);
    }
}

pub inline fn pr_debug(comptime fmt: []const u8, args: anytype) void {
    if (@intFromEnum(LogLevel) >= @intFromEnum(Level.Debug)) {
        console.print(ansi_fmt("[DEBUG] [kernel]", Color.Green), .{});
        console.print(ansi_fmt(fmt, Color.Green), args);
    }
}

pub inline fn pr_trace(comptime fmt: []const u8, args: anytype) void {
    if (@intFromEnum(LogLevel) >= @intFromEnum(Level.Trace)) {
        console.print(ansi_fmt("[TRACE] [kernel]", Color.Gray), .{});
        console.print(ansi_fmt(fmt, Color.Gray), args);
    }
}

pub inline fn panic(comptime src: std.builtin.SourceLocation, comptime fmt: []const u8, args: anytype) void {
    console.print(ansi_fmt("[Kernel] Panicked at {s}:{d} ", Color.Red), .{ src.file, src.line });
    console.print(ansi_fmt(fmt ++ "\n", Color.Red), args);
    sbi.shutdown();
}
