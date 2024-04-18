const lib = @import("lib");

pub fn main() !void {
    lib.print("Try to access privileged CSR in U Mode\n", .{});
    lib.print("Kernel should kill this application!\n", .{});
    setSstatus(1 << 8);
}

pub inline fn setSstatus(value: usize) void {
    asm volatile ("csrs sstatus, %[value]"
        :
        : [value] "r" (value),
    );
}
