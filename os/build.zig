const std = @import("std");
const logLevel = @import("src/log.zig").Level;

pub fn build(b: *std.Build) void {
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
