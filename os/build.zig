const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = std.zig.CrossTarget{
        .cpu_arch = .riscv64,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_model = .{ .explicit = &std.Target.riscv.cpu.generic_rv64 },
        .cpu_features_add = std.Target.riscv.featureSet(&.{ .m, .a, .c, .zicsr }),
    };

    const os = b.addExecutable(.{
        .name = "os.elf",
        .root_source_file = .{ .path = "src/entry.zig" },
        .target = b.resolveTargetQuery(target),
        .optimize = .ReleaseSafe,
    });
    os.root_module.code_model = .medium;

    os.setLinkerScript(.{ .path = "src/linker.ld" });

    b.installArtifact(os);

    const bin = os.addObjCopy(.{
        .basename = "os.bin",
        .format = .bin,
    });
    const install_bin = b.addInstallBinFile(bin.getOutputSource(), bin.basename);
    b.default_step.dependOn(&install_bin.step);
}
