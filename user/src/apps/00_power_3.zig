const lib = @import("lib");
const print = lib.print;

const LEN: usize = 100;

pub fn main() !void {
    const p: u64 = 3;
    const m: u64 = 998244353;
    const iter: usize = 200000;
    var s = [_]u64{0} ** LEN;
    var cur: usize = 0;
    s[cur] = 1;
    for (1..iter + 1) |i| {
        const next = if (cur + 1 == LEN) 0 else cur + 1;
        s[next] = s[cur] * p % m;
        cur = next;
        if (i % 10000 == 0) {
            print("power_3 [{}/{}]\n", .{ i, iter });
        }
    }
    print("{}^{} = {}(MOD {})\n", .{ p, iter, s[cur], m });
    print("Test power_3 OK!\n", .{});
}
