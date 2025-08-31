all:
	nasm ./src/boot.asm -f bin -o ./bin/boot.bin

clean:
	rm ./bin/boot.bin
