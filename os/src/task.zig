const std = @import("std");
const loader = @import("loader.zig");
const consts = @import("consts.zig");
const log = @import("log.zig");
const console = @import("console.zig");
const sbi = @import("sbi.zig");

pub var task_manager: TaskManager = undefined;

pub fn init() void {
    const num_app = loader.getNumApp();
    var tasks: [consts.MAX_APP_NUM]TaskControlBlock = undefined;
    for (&tasks, 0..) |*task, i| {
        task.task_cx = TaskContext.gotoRestore(loader.initAppCx(i));
        task.task_status = .Ready;
    }
    task_manager = .{
        .num_app = num_app,
        .tasks = tasks,
        .current_task = 0,
    };
}

/// The task manager, where all the tasks are managed.
///
/// Functions implemented on `TaskManager` deals with all task state transitions
/// and task context switching. For convenience, you can find wrappers around it
/// in the module level.
pub const TaskManager = struct {
    num_app: usize,
    tasks: [consts.MAX_APP_NUM]TaskControlBlock,
    current_task: usize,

    const Self = @This();

    /// Run the first task in task list.
    ///
    /// Generally, the first task in task list is an idle task (we call it zero process later).
    /// But in ch3, we load apps statically, so the first task is a real app.
    fn runFirstTask(self: *Self) void {
        var task0 = self.tasks[0];
        task0.task_status = .Running;
        const next_task_cx_ptr: *TaskContext = &task0.task_cx;
        var _unused = TaskContext.zero_init();
        __switch(&_unused, next_task_cx_ptr);
        log.panic(@src(), "unreachable in runFirstTask", .{});
    }

    /// Change the status of current `Running` task into `Ready`.
    pub fn markCurrentSuspended(self: *Self) void {
        self.tasks[self.current_task].task_status = .Ready;
    }

    /// Change the status of current `Running` task into `Exited`.
    pub fn markCurrentExited(self: *Self) void {
        self.tasks[self.current_task].task_status = .Exited;
    }

    /// Find next task to run and return app id.
    ///
    /// In this case, we only return the first `Ready` task in the task list.
    fn findNextTask(self: *Self) ?usize {
        const current = self.current_task;
        for (current + 1..current + self.num_app + 1) |i| {
            const id = i % self.num_app;
            if (self.tasks[id].task_status == .Ready)
                return id;
        }
        return null;
    }

    /// Switch current `Running` task to the task we have found,
    /// or there is no `Ready` task and we can exit with all applications completed
    pub fn runNextTask(self: *Self) void {
        if (self.findNextTask()) |next| {
            const current = self.current_task;
            self.tasks[next].task_status = .Running;
            self.current_task = next;
            const current_task_cx_ptr: *TaskContext = &self.tasks[current].task_cx;
            const next_task_cx_ptr: *TaskContext = &self.tasks[next].task_cx;
            __switch(current_task_cx_ptr, next_task_cx_ptr);
        } else {
            console.print("All applications completed!\n", .{});
            sbi.shutdown();
        }
    }
};

/// Run the first task.
pub fn runFirstTask() void {
    task_manager.runFirstTask();
}

/// Run the next task.
pub fn runNextTask() void {
    task_manager.runNextTask();
}

/// Suspend current task.
pub fn markCurrentSuspended() void {
    task_manager.markCurrentSuspended();
}

/// Exit current task.
pub fn markCurrentExited() void {
    task_manager.markCurrentExited();
}

/// Suspend current task, then run next task
pub fn suspendCurrentAndRunNext() void {
    markCurrentSuspended();
    runNextTask();
}

/// Exit current task, then run next task
pub fn exitCurrentAndRunNext() void {
    markCurrentExited();
    runNextTask();
}

/// Task Context
pub const TaskContext = extern struct {
    /// return address ( e.g. __restore ) of __switch ASM function
    ra: usize,
    /// kernel stack pointer of app
    sp: usize,
    /// callee saved registers: s0..s11
    s: [12]usize,

    const Self = @This();

    /// Init task context
    pub fn zero_init() Self {
        return .{
            .ra = 0,
            .sp = 0,
            .s = [_]usize{0} ** 12,
        };
    }

    /// Set task context {__restore ASM function, kernel stack, {0} ** 12}
    pub fn gotoRestore(kstack_ptr: usize) Self {
        return .{
            .ra = @intFromPtr(@extern(*const fn (usize) callconv(.C) noreturn, .{ .name = "__restore" })),
            .sp = kstack_ptr,
            .s = [_]usize{0} ** 12,
        };
    }
};

/// Task status
pub const TaskStatus = enum {
    UnInit,
    Ready,
    Running,
    Exited,
};

/// Task control block
pub const TaskControlBlock = struct {
    task_status: TaskStatus,
    task_cx: TaskContext,
};

pub extern fn __switch(current_task_cx_ptr: *TaskContext, next_task_cx_ptr: *TaskContext) callconv(.C) noreturn;
comptime {
    asm (
        \\    .altmacro
        \\.macro SAVE_SN n
        \\    sd s\n, (\n+2)*8(a0)
        \\.endm
        \\.macro LOAD_SN n
        \\    ld s\n, (\n+2)*8(a1)
        \\.endm
        \\    .section .text
        \\    .globl __switch
        \\__switch:
        \\    # __switch(
        \\    #     current_task_cx_ptr: *mut TaskContext,
        \\    #     next_task_cx_ptr: *const TaskContext
        \\    # )
        \\    # save kernel stack of current task
        \\    sd sp, 8(a0)
        \\    # save ra & s0~s11 of current execution
        \\    sd ra, 0(a0)
        \\    .set n, 0
        \\    .rept 12
        \\        SAVE_SN %n
        \\        .set n, n + 1
        \\    .endr
        \\    # restore ra & s0~s11 of next execution
        \\    ld ra, 0(a1)
        \\    .set n, 0
        \\    .rept 12
        \\        LOAD_SN %n
        \\        .set n, n + 1
        \\    .endr
        \\    # restore kernel stack of next task
        \\    ld sp, 8(a1)
        \\    ret
    );
}
