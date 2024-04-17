const std = @import("std");
const logLevel = @import("src/log.zig").Level;

pub fn build(b: *std.Build) !void {
    try loadApp(b.allocator);

    const target = std.zig.CrossTarget{
        .cpu_arch = .riscv64,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_model = .{ .explicit = &std.Target.riscv.cpu.generic_rv64 },
        .cpu_features_add = std.Target.riscv.featureSet(&.{ .m, .a, .c, .zicsr }),
    };
    const optimize = b.standardOptimizeOption(.{});

    const os = b.addExecutable(.{
        .name = "os.elf",
        .root_source_file = .{ .path = "src/entry.zig" },
        .target = b.resolveTargetQuery(target),
        .optimize = optimize,
    });
    os.root_module.code_model = .medium;

    const log_level = b.option(logLevel, "log", "Log Level") orelse .None;
    const options = b.addOptions();
    options.addOption(logLevel, "Log", log_level);
    os.root_module.addOptions("config", options);

    os.setLinkerScript(.{ .path = "src/linker.ld" });

    b.installArtifact(os);

    const bin = os.addObjCopy(.{
        .basename = "os.bin",
        .format = .bin,
    });
    const install_bin = b.addInstallBinFile(bin.getOutputSource(), bin.basename);
    b.default_step.dependOn(&install_bin.step);
}

fn loadApp(allocator: std.mem.Allocator) !void {
    const bin_path = "../user/zig-out/bin";

    var dir = std.fs.cwd().openDir(bin_path, .{
        .iterate = true,
    }) catch @panic("Please build user first!");
    defer dir.close();

    const file = try std.fs.cwd().createFile("src/link_app.zig", .{});
    defer file.close();
    const writer = file.writer();

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    var apps_array = std.ArrayList([]const u8).init(allocator);
    defer apps_array.deinit();

    while (try walker.next()) |entry| {
        if (!std.mem.endsWith(u8, entry.basename, ".bin")) {
            continue;
        }
        const basename = try std.fmt.allocPrint(allocator, "{s}", .{entry.basename});
        try apps_array.append(basename);
    }

    const apps = try apps_array.toOwnedSlice();
    std.mem.sort([]const u8, apps, {}, struct {
        pub fn lessThan(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.lessThan);

    try writer.writeAll(
        \\comptime {
        \\    asm(
        \\        \\    .align 3
        \\        \\    .section .data
        \\        \\    .global _num_app
        \\        \\_num_app:
        \\
    );
    try writer.print("        \\\\    .quad {d}\n", .{apps.len});

    for (0..apps.len) |i| {
        try writer.print("        \\\\    .quad app_{d}_start\n", .{i});
    }

    try writer.print("        \\\\    .quad app_{d}_end\n", .{apps.len - 1});

    for (apps, 0..) |app, i| {
        std.debug.print("app_{d}: {s}\n", .{ i, app });

        try writer.print(
            \\        \\    .section .data
            \\        \\    .global app_{0d}_start
            \\        \\    .global app_{0d}_end
            \\        \\app_{0d}_start:
            \\        \\    .incbin "{2s}/{1s}"
            \\        \\app_{0d}_end:
            \\
        , .{ i, app, bin_path });
    }

    try writer.writeAll(
        \\    );
        \\}
        \\
    );
}
