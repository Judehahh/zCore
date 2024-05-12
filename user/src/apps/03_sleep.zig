const lib = @import("lib");
const print = lib.print;
const yield_ = lib.yield_;
const getTime = lib.getTime;

pub fn main() !void {
    const current_timer = getTime();
    const wait_for = current_timer + 3000;
    while (getTime() < wait_for) {
        _ = yield_();
    }
    print("Test sleep OK!\n", .{});
}
