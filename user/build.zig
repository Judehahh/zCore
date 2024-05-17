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

    var apps_basename_array = std.ArrayList([]const u8).init(b.allocator);
    defer apps_basename_array.deinit();

    while (try walker.next()) |entry| {
        if (!std.mem.endsWith(u8, entry.basename, ".zig")) {
            continue;
        }
        const basename = try std.fmt.allocPrint(b.allocator, "{s}", .{entry.basename});
        try apps_basename_array.append(basename);
    }

    const apps_basename = try apps_basename_array.toOwnedSlice();
    std.mem.sort([]const u8, apps_basename, {}, struct {
        pub fn lessThan(_: void, x: []const u8, y: []const u8) bool {
            return std.mem.lessThan(u8, x, y);
        }
    }.lessThan);

    // For linker scripts.
    var base_address: usize = 0x80400000;
    const step = 0x20000;
    var linker_origin_file = try std.fs.cwd().openFile("src/linker.ld", .{ .mode = .read_write });
    defer linker_origin_file.close();
    const linker_origin_src = try linker_origin_file.readToEndAlloc(b.allocator, std.math.maxInt(usize));

    for (apps_basename) |app_basename| {
        const app_name = app_basename[0 .. app_basename.len - 4];
        const app_path = try std.fmt.allocPrint(b.allocator, "src/apps/{s}", .{app_basename});

        // Prepare a linker script.
        const linker_path = try std.fmt.allocPrint(b.allocator, "src/{s}.ld.tmp", .{app_name});

        const needle = try std.fmt.allocPrint(b.allocator, "0x{x}", .{0x80400000});
        const replacement = try std.fmt.allocPrint(b.allocator, "0x{x}", .{base_address});
        const linker_src = try b.allocator.alloc(u8, linker_origin_src.len);
        defer b.allocator.free(linker_src);
        _ = std.mem.replace(u8, linker_origin_src, needle, replacement, linker_src);

        const linker_file = try std.fs.cwd().createFile(linker_path, .{});
        defer linker_file.close();
        try linker_file.writeAll(linker_src);

        std.debug.print("building app: {s}, start with address: 0x{x}\n", .{ app_name, base_address });
        base_address += step;

        // Start to build the app.
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

        exe.setLinkerScript(b.path(linker_path));

        b.installArtifact(exe);

        // elf to bin
        const bin_name = try std.fmt.allocPrint(b.allocator, "{s}.bin", .{app_name});

        const bin = exe.addObjCopy(.{
            .basename = bin_name,
            .format = .bin,
        });
        const install_bin = b.addInstallBinFile(bin.getOutputSource(), bin.basename);
        b.default_step.dependOn(&install_bin.step);
    }
}
