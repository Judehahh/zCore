const sbi = @import("sbi.zig");
const console = @import("console.zig");

pub fn kmain() void {
    console.print("hello {s}\n", .{"zCore"});
    sbi.shutdown();
}
