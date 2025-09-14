# specify that main commands are not files in directory
# (ex: Makefile will run as expected even if there's a file named "clean")
.PHONY: all clean boot

# nasm 64 bits compiling
NASM := nasm -f elf64
# compiler name and flags for 64 bits
CC := x86_64-elf-gcc
CFLAGS := -ffreestanding -mcmodel=large -mno-red-zone -mno-mmx -mno-sse -mno-sse2

# directories
SRC_BOOT := src/boot
SRC_KERNEL := src/kernel
BUILD_DIR := build

# find all sources
BOOT_ASM_SRCS := $(wildcard $(SRC_BOOT)/**/*.asm) $(wildcard $(SRC_BOOT)/*.asm)
KERNEL_C_SRCS := $(wildcard $(SRC_KERNEL)/**/*.c) $(wildcard $(SRC_KERNEL)/*.c)

# build object list from sources
BOOT_OBJS := $(patsubst $(SRC_BOOT)/%.asm,$(BUILD_DIR)/boot/%.o,$(BOOT_ASM_SRCS))
KERNEL_OBJS := $(patsubst $(SRC_KERNEL)/%.c,$(BUILD_DIR)/kernel/%.o,$(KERNEL_C_SRCS))

# generated object files
OBJS := $(BOOT_OBJS) $(KERNEL_OBJS)

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
$(BUILD_DIR)/boot/%.o: $(SRC_BOOT)/%.asm
	@mkdir -p $(dir $@)
	$(NASM) $< -o $@

# compile sources (c) into object files
$(BUILD_DIR)/kernel/%.o: $(SRC_KERNEL)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# compile project
all: $(BOOT_IMAGE)

# clean generated files
clean:
	$(RM) -r $(BUILD_DIR)

# run operating system in qemu
run:
	qemu-system-x86_64 -no-reboot -drive file=build/boot_image.bin,format=raw,index=0,media=disk
