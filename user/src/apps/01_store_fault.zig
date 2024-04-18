const lib = @import("lib");

pub fn main() !void {
    lib.print("Into Test store_fault, we will insert an invalid store operation...\n", .{});
    lib.print("Kernel should kill this application!\n", .{});
    const ptr: *u8 = @ptrFromInt(0x80000000);
    ptr.* = 0;
}
