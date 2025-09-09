# os

## Boot assembly

Build bootloader

```bash
make all
```

Clean generated files

```bash
make clean
```

Test bootloader with qemu on x86_64

```bash
make run
```

## Misc

Check os binary file

```bash
bless os.bin
```

Use gdb (kernel_address is set at 0x8000 in linker.ld)

```bash
add-symbol-file ./build/linked.o [kernel_address]
break kernel_entry
target remote | qemu-system-x86_64 -hda ./build/boot_image.bin -gdb stdio -S
```
