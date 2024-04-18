const std = @import("std");
const riscv = @import("riscv.zig");
const log = @import("log.zig");
const syscall = @import("syscall.zig").syscall;

pub const Trap = union(enum) {
    Interrupt: Interrupt,
    Exception: Exception,
};

pub const Interrupt = enum {
    UserSoft,
    SupervisorSoft,
    VirtualSupervisorSoft,
    UserTimer,
    SupervisorTimer,
    VirtualSupervisorTimer,
    UserExternal,
    VirtualSupervisorExternal,
    SupervisorExternal,
    Unknown,

    pub fn from(nr: usize) Interrupt {
        return switch (nr) {
            0 => .UserSoft,
            1 => .SupervisorSoft,
            2 => .VirtualSupervisorSoft,
            4 => .UserTimer,
            5 => .SupervisorTimer,
            6 => .VirtualSupervisorTimer,
            8 => .UserExternal,
            9 => .SupervisorExternal,
            10 => .VirtualSupervisorExternal,
            else => .Unknown,
        };
    }
};

pub const Exception = enum {
    InstructionMisaligned,
    InstructionFault,
    IllegalInstruction,
    Breakpoint,
    LoadFault,
    StoreMisaligned,
    StoreFault,
    UserEnvCall,
    VirtualSupervisorEnvCall,
    InstructionPageFault,
    LoadPageFault,
    StorePageFault,
    InstructionGuestPageFault,
    LoadGuestPageFault,
    VirtualInstruction,
    StoreGuestPageFault,
    Unknown,

    pub fn from(nr: usize) Exception {
        return switch (nr) {
            0 => .InstructionMisaligned,
            1 => .InstructionFault,
            2 => .IllegalInstruction,
            3 => .Breakpoint,
            5 => .LoadFault,
            6 => .StoreMisaligned,
            7 => .StoreFault,
            8 => .UserEnvCall,
            10 => .VirtualSupervisorEnvCall,
            12 => .InstructionPageFault,
            13 => .LoadPageFault,
            15 => .StorePageFault,
            20 => .InstructionGuestPageFault,
            21 => .LoadGuestPageFault,
            22 => .VirtualInstruction,
            23 => .StoreGuestPageFault,
            else => .Unknown,
        };
    }
};

extern fn __alltraps() callconv(.Naked) void;

pub fn init() void {
    riscv.Stvec.write(@intFromPtr(&__alltraps), .Direct);
}

pub export fn trap_handler(cx: *TrapContext) *TrapContext {
    const scause = riscv.Scause.read();
    const stval = riscv.Stval.read().bits.mask;
    switch (scause.cause()) {
        .Exception => |e| switch (e) {
            .UserEnvCall => {
                cx.sepc += 4;
                cx.x[10] = syscall(@enumFromInt(cx.x[17]), cx.x[10], cx.x[11], cx.x[12]);
            },
            else => {
                log.panic(
                    @src(),
                    "Unsupported trap {s}, stval = 0x{x}, sepc = 0x{x}",
                    .{ @tagName(e), stval, cx.sepc },
                );
            },
        },
        .Interrupt => log.panic(@src(), "Interrupt is not suppoerted", .{}),
    }
    return cx;
}

comptime {
    if (@sizeOf(TrapContext) != 34 * 8) {
        @compileError("Failed");
    }
}

pub const TrapContext = struct {
    x: [32]usize,
    sstatus: riscv.Sstatus,
    sepc: usize,
    const Self = @This();

    pub fn setSp(self: *Self, sp: usize) void {
        self.x[2] = sp;
    }

    pub fn init(entry: usize, sp: usize) Self {
        var sstatus = riscv.Sstatus.read();
        sstatus.setSpp(.User);
        var cx = Self{
            .x = std.mem.zeroes([32]usize),
            .sstatus = sstatus,
            .sepc = entry,
        };
        cx.setSp(sp);
        return cx;
    }
};

comptime {
    asm (
        \\.altmacro
        \\.macro SAVE_GP n
        \\    sd x\n, \n*8(sp)
        \\.endm
        \\.macro LOAD_GP n
        \\    ld x\n, \n*8(sp)
        \\.endm
        \\    .section .text
        \\    .globl __alltraps
        \\    .globl __restore
        \\    .align 2
        \\__alltraps:
        \\    csrrw sp, sscratch, sp
        \\    # now sp->kernel stack, sscratch->user stack
        \\    # allocate a TrapContext on kernel stack
        \\    addi sp, sp, -34*8
        \\    # save general-purpose registers
        \\    sd x1, 1*8(sp)
        \\    # skip sp(x2), we will save it later
        \\    sd x3, 3*8(sp)
        \\    # skip tp(x4), application does not use it
        \\    # save x5~x31
        \\    .set n, 5
        \\    .rept 27
        \\        SAVE_GP %n
        \\        .set n, n+1
        \\    .endr
        \\    # we can use t0/t1/t2 freely, because they were saved on kernel stack
        \\    csrr t0, sstatus
        \\    csrr t1, sepc
        \\    sd t0, 32*8(sp)
        \\    sd t1, 33*8(sp)
        \\    # read user stack from sscratch and save it on the kernel stack
        \\    csrr t2, sscratch
        \\    sd t2, 2*8(sp)
        \\    # set input argument of trap_handler(cx: &mut TrapContext)
        \\    mv a0, sp
        \\    call trap_handler
        \\
        \\__restore:
        \\    # case1: start running app by __restore
        \\    # case2: back to U after handling trap
        \\    mv sp, a0
        \\    # now sp->kernel stack(after allocated), sscratch->user stack
        \\    # restore sstatus/sepc
        \\    ld t0, 32*8(sp)
        \\    ld t1, 33*8(sp)
        \\    ld t2, 2*8(sp)
        \\    csrw sstatus, t0
        \\    csrw sepc, t1
        \\    csrw sscratch, t2
        \\    # restore general-purpuse registers except sp/tp
        \\    ld x1, 1*8(sp)
        \\    ld x3, 3*8(sp)
        \\    .set n, 5
        \\    .rept 27
        \\        LOAD_GP %n
        \\        .set n, n+1
        \\    .endr
        \\    # release TrapContext on kernel stack
        \\    addi sp, sp, 34*8
        \\    # now sp->kernel stack, sscratch->user stack
        \\    csrrw sp, sscratch, sp
        \\    sret
    );
}
