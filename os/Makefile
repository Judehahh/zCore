# Building
MODE := ReleaseSafe
KERNEL_ELF := zig-out/bin/os.elf
KERNEL_BIN := zig-out/bin/os.bin
DISASM_TMP := zig-out/bin/os.asm

# BOARD
BOARD := qemu

# Binutils
ifneq ($(shell which riscv64-elf-gcc 2>/dev/null),)
	CROSS_COMPILE := riscv64-elf-
else
	CROSS_COMPILE := riscv64-unknown-elf-
endif
OBJDUMP := $(CROSS_COMPILE)objdump
GDB := $(CROSS_COMPILE)gdb

# Disassembly
DISASM ?= -x -S

kernel:
	@echo Platform: $(BOARD)
	@cp src/linker-$(BOARD).ld src/linker.ld
	@zig build -Doptimize=${MODE}
	@rm src/linker.ld

clean:
	@rm -rf zig-cache zig-out src/linker.ld

disasm: kernel
	@$(OBJDUMP) $(DISASM) $(KERNEL_ELF) | less

disasm-vim: kernel
	@$(OBJDUMP) $(DISASM) $(KERNEL_ELF) > $(DISASM_TMP)
	@vim $(DISASM_TMP)
	@rm $(DISASM_TMP)

disasm-nvim: kernel
	@$(OBJDUMP) $(DISASM) $(KERNEL_ELF) > $(DISASM_TMP)
	@nvim $(DISASM_TMP)
	@rm $(DISASM_TMP)

run: run-inner

QEMU := qemu-system-riscv64
QEMU_ARGS := -machine virt \
			 -nographic \
			 -kernel $(KERNEL_BIN)

run-inner: kernel
	@$(QEMU) $(QEMU_ARGS)

debug: kernel
	@tmux new-session -d \
		"$(QEMU) $(QEMU_ARGS) -s -S"; \
		tmux split-window -h "$(GDB) -ex 'file $(KERNEL_ELF)' -ex 'set arch riscv:rv64' -ex 'target remote localhost:1234'" && \
		tmux -2 attach-session -d

gdbserver: kernel
	@$(QEMU) $(QEMU_ARGS) -s -S

gdbclient:
	@$(GDB) -ex 'file $(KERNEL_ELF)' -ex 'set arch riscv:rv64' -ex 'target remote localhost:1234'

.PHONY: build env kernel clean disasm disasm-vim disasm-nvim run-inner gdbserver gdbclient
