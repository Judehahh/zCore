const lib = @import("lib");

const size: usize = 10;
const p: u32 = 3;
const step: usize = 100000;
const mod: u32 = 10007;

pub fn main() !void {
    var pow: [size]u32 = [_]u32{0} ** size;
    var index: usize = 0;
    pow[index] = 1;
    for (1..step + 1) |i| {
        const last = pow[index];
        index = (index + 1) % size;
        pow[index] = last * p % mod;
        if (i % 10000 == 0) {
            lib.print("{}^{}={}(MOD {})\n", .{ p, i, pow[index], mod });
        }
    }
    lib.print("Test power OK!\n", .{});
}
