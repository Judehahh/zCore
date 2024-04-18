const lib = @import("lib");

pub fn main() !void {
    lib.print("Try to execute privileged instruction in U Mode\n", .{});
    lib.print("Kernel should kill this application!\n", .{});
    asm volatile ("sret");
}
