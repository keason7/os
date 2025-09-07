build:
	nasm ./src/boot.asm -f bin -o ./bin/boot.bin

clean:
	rm ./bin/boot.bin

run:
	qemu-system-x86_64 -drive format=raw,file=./bin/boot.bin