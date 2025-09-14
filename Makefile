# specify that main commands are not files in directory
# (ex: Makefile will run as expected even if there's a file named "clean")
.PHONY: all clean boot

# nasm 64 bits compiling
NASM := nasm -f elf64
# compiler name and flags for 64 bits
CC := x86_64-elf-gcc
CFLAGS := -ffreestanding -mcmodel=large -mno-red-zone -mno-mmx -mno-sse -mno-sse2

# directories
SRC := src
BUILD_DIR := build

# find asm and c source files path
SRC_ASM = $(shell find $(SRC) -type f -name '*.asm')
SRC_C = $(shell find $(SRC) -type f -name '*.c')

# replace path from src/ entry folder to build/
# ex: src/kernel/kernel.c -> build/kernel/kernel.c.o
OBJS_ASM := $(patsubst $(SRC)/%.asm,$(BUILD_DIR)/%.asm.o,$(SRC_ASM))
OBJS_C := $(patsubst $(SRC)/%.c,$(BUILD_DIR)/%.c.o,$(SRC_C))

# group asm and c object paths
OBJS := $(OBJS_ASM) $(OBJS_C)

# final boot image for qemu
BOOT_IMAGE := $(BUILD_DIR)/boot_image.bin
# linker object file
LINKED_OBJ := $(BUILD_DIR)/linked.o

# link all object files into a single linked ELF object
$(LINKED_OBJ): $(OBJS)
	@mkdir -p $(dir $@)
	ld -T linker.ld -o $@ $^

# convert ELF to flat binary
$(BOOT_IMAGE): $(LINKED_OBJ)
	objcopy -O binary $< $@

# compile sources (asm) into object files
$(BUILD_DIR)/%.asm.o: $(SRC)/%.asm
	@mkdir -p $(dir $@)
	$(NASM) $< -o $@

# compile sources (c) into object files
# arg -I allow to include .h files without relative imports
$(BUILD_DIR)/%.c.o: $(SRC)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -I $(SRC)/kernel -c $< -o $@


# compile project
all: $(BOOT_IMAGE)

# clean generated files
clean:
	$(RM) -r $(BUILD_DIR)

# run operating system in qemu
run:
	qemu-system-x86_64 -no-reboot -drive file=build/boot_image.bin,format=raw,index=0,media=disk
