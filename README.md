# os

## Build the OS

Specify cross-compiler options (before compiling OS) for current shell session

```bash
# run these commands in terminal or copy these to ~/.bashrc
export PREFIX="$HOME/opt/cross"
export TARGET=x86_64-elf
export PATH="$PREFIX/bin:$PATH"
```

Build bootloader and kernel

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

## Cross compiler installation

Install necessary libs

```bash
sudo apt install build-essential bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo libisl-dev
```

Download lastest gcc and binutils as .tar.gz

```txt
https://ftp.gnu.org/gnu/gcc
https://ftp.gnu.org/gnu/binutils/
```

Extract them at

```bash
/home/{username}/.cross_compiler
```

Export cross compiler parameters (target for 64 bits systems)

```bash
export PREFIX="$HOME/opt/cross"
export TARGET=x86_64-elf
export PATH="$PREFIX/bin:$PATH"
```

Build binutils

```bash
cd $HOME/.cross_compiler
mkdir build-binutils
cd build-binutils/
../binutils-2.44/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror
make
make install
```

Build gcc

```bash
cd $HOME/.cross_compiler
which -- $TARGET-as || echo $TARGET-as is not in the PATH
mkdir build-gcc
cd build-gcc
../gcc-15.2.0/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers --disable-hosted-libstdcxx
make all-gcc
make all-target-libgcc
make all-target-libstdc++-v3
make install-gcc
make install-target-libgcc
make install-target-libstdc++-v3
```

Test that it worked

```bash
$HOME/opt/cross/bin/$TARGET-gcc --version
```

## Misc

Check OS binary file

```bash
bless boot_image.bin
```

Use gdb (kernel_address is set at 0x8000 in linker.ld)

```bash
add-symbol-file ./build/linked.o [kernel_address]
break kernel_entry
target remote | qemu-system-x86_64 -hda ./build/boot_image.bin -gdb stdio -S
```
