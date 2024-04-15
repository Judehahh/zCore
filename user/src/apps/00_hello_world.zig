const lib = @import("lib");

export fn main() i32 {
    lib.console.print("Hello from {s}!\n", .{"user"});

    return 0;
}
