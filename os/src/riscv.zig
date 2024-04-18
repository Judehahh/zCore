const std = @import("std");
const Bits = std.bit_set.IntegerBitSet(@bitSizeOf(usize));
const trap = @import("trap.zig");

pub const CSRs = enum {
    sstatus,
    stvec,
    scause,
    stval,

    inline fn read(reg: CSRs) usize {
        return asm volatile ("csrr %[ret], " ++ @tagName(reg)
            : [ret] "=r" (-> u64),
        );
    }

    inline fn write(reg: CSRs, value: usize) void {
        asm volatile ("csrw " ++ @tagName(reg) ++ ", %[value]"
            :
            : [value] "r" (value),
        );
    }
};

pub const Sstatus = struct {
    bits: Bits,

    const tag: CSRs = .sstatus;
    const Self = @This();

    pub fn read() Self {
        return .{ .bits = .{ .mask = tag.read() } };
    }

    pub const SPP = enum {
        Supervisor,
        User,
    };

    pub fn setSpp(self: *Self, val: SPP) void {
        self.bits.setValue(8, val == .Supervisor);
    }
};

pub const Stvec = struct {
    bits: Bits,

    const tag: CSRs = .stvec;
    const Self = @This();

    pub fn read() Self {
        return .{ .bits = .{ .mask = tag.read() } };
    }

    pub const TrapMode = enum(u1) {
        Direct = 0,
        Vectored = 1,
    };

    pub fn write(addr: usize, mode: TrapMode) void {
        tag.write(addr + @intFromEnum(mode));
    }

    pub fn address(self: Self) usize {
        return self.bits.mask - (self.bits.mask & 0b11);
    }
};

pub const Scause = struct {
    bits: Bits,

    const tag: CSRs = .scause;
    const Self = @This();

    pub fn read() Self {
        return .{ .bits = .{ .mask = tag.read() } };
    }

    pub fn code(self: Self) usize {
        const bit: usize = 1 << (@bitSizeOf(usize) - 1);
        return self.bits.mask & ~bit;
    }

    pub fn cause(self: Self) trap.Trap {
        return if (self.isInterrupt())
            trap.Trap{ .Interrupt = trap.Interrupt.from(self.code()) }
        else
            trap.Trap{ .Exception = trap.Exception.from(self.code()) };
    }

    pub inline fn isInterrupt(self: Self) bool {
        return self.bits.isSet(@bitSizeOf(usize) - 1);
    }

    pub inline fn isException(self: Self) bool {
        return !self.isInterrupt();
    }
};

pub const Stval = struct {
    bits: Bits,

    const tag: CSRs = .stval;
    const Self = @This();

    pub fn read() Self {
        return .{ .bits = .{ .mask = tag.read() } };
    }
};
