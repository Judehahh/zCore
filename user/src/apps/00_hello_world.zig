const lib = @import("lib");

pub fn main() !void {
    lib.print("Hello from {s}!\n", .{"user"});
}
