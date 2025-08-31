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

Test with qemu

```bash
qemu-system-i386 -hda ./bin/boot.bin
```
