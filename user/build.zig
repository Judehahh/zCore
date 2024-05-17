const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .riscv64,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_model = .{ .explicit = &std.Target.riscv.cpu.generic_rv64 },
        .cpu_features_add = std.Target.riscv.featureSet(&.{ .m, .a, .c, .zicsr }),
    });
    const optimize = b.standardOptimizeOption(.{});

    const lib_module = b.addModule("lib", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    var apps_dir = try std.fs.cwd().openDir("src/apps", .{ .iterate = true });
    defer apps_dir.close();

    var walker = try apps_dir.walk(b.allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (!std.mem.endsWith(u8, entry.basename, ".zig")) {
            continue;
        }

        const app_name = entry.basename[0 .. entry.basename.len - 4];
        const app_path = try std.fmt.allocPrint(b.allocator, "src/apps/{s}", .{entry.basename});

        std.debug.print("building app: {s}\n", .{app_name});

        const app_module = b.addModule("app", .{
            .root_source_file = b.path(app_path),
            .target = target,
            .optimize = optimize,
        });
        app_module.addImport("lib", lib_module);

        const exe = b.addExecutable(.{
            .name = app_name,
            .root_source_file = b.path("src/start.zig"),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.code_model = .medium;

        exe.root_module.addImport("app", app_module);
        exe.root_module.addImport("lib", lib_module);

        exe.setLinkerScript(b.path("src/linker.ld"));

        b.installArtifact(exe);

        const bin_name = try std.fmt.allocPrint(b.allocator, "{s}.bin", .{app_name});

        const bin = exe.addObjCopy(.{
            .basename = bin_name,
            .format = .bin,
        });
        const install_bin = b.addInstallBinFile(bin.getOutputSource(), bin.basename);
        b.default_step.dependOn(&install_bin.step);
    }
}
