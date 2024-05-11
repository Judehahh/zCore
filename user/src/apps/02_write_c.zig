const lib = @import("lib");
const print = lib.print;
const yield_ = lib.yield_;

const WIDTH: usize = 10;
const HEIGHT: usize = 3;

pub fn main() !void {
    for (0..HEIGHT) |i| {
        for (0..WIDTH) |_| {
            print("C", .{});
        }
        print(" [{}/{}]\n", .{ i + 1, HEIGHT });
        _ = yield_();
    }
    print("Test write_c OK!\n", .{});
}
