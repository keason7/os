# specify that main commands are not files in directory
# (ex: Makefile will run as expected even if there's a file named "clean")
.PHONY: all clean boot

# nasm 64 bits compiling
NASM := nasm -f elf64
# compiler name and flags for 64 bits
CC := x86_64-elf-gcc
CFLAGS := -ffreestanding -mcmodel=large -mno-red-zone -mno-mmx -mno-sse -mno-sse2

# output build directory
BUILD_DIR := build

# final boot image for qemu
BOOT_IMAGE := $(BUILD_DIR)/boot_image.bin

# linked object file
LINKED_OBJ := $(BUILD_DIR)/linked.o

# generated object files
OBJS := \
	$(BUILD_DIR)/boot/boot_stage_1.o \
	$(BUILD_DIR)/boot/boot_stage_2.o \
	$(BUILD_DIR)/boot/gdt_32.o \
	$(BUILD_DIR)/boot/gdt_64.o \
	$(BUILD_DIR)/boot/paging.o \
	$(BUILD_DIR)/kernel/kernel.o

# convert the linked ELF object into a raw binary boot image
$(BOOT_IMAGE): $(LINKED_OBJ)
	objcopy -O binary $< $@

# link all object files into a single linked ELF object
$(LINKED_OBJ): $(OBJS)
	@mkdir -p $(dir $@)
	ld -T linker.ld -o $@ $^

# compile sources into object files
$(BUILD_DIR)/boot/boot_stage_1.o: src/boot/boot_stage_1.asm
	@mkdir -p $(dir $@)
	$(NASM) $< -o $@
$(BUILD_DIR)/boot/boot_stage_2.o: src/boot/boot_stage_2.asm
	@mkdir -p $(dir $@)
	$(NASM) $< -o $@
$(BUILD_DIR)/boot/gdt_32.o: src/boot/gdt/gdt_32.asm
	@mkdir -p $(dir $@)
	$(NASM) $< -o $@
$(BUILD_DIR)/boot/gdt_64.o: src/boot/gdt/gdt_64.asm
	@mkdir -p $(dir $@)
	$(NASM) $< -o $@
$(BUILD_DIR)/boot/paging.o: src/boot/paging.asm
	@mkdir -p $(dir $@)
	$(NASM) $< -o $@
$(BUILD_DIR)/kernel/kernel.o: src/kernel/kernel.c
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
