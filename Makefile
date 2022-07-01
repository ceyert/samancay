FILES = ./build/kernel.S.o

all: ./bin/boot.bin ./bin/kernel.bin
	dd if=./bin/boot.bin >> ./bin/os.bin
	dd if=./bin/kernel.bin >> ./bin/os.bin
	dd if=/dev/zero bs=512 count=100 >> ./bin/os.bin

# https://wiki.osdev.org/GCC_Cross-Compiler go to Prebuilt Toolchains 

./bin/kernel.bin: $(FILES)
	${HOME}/Desktop/samancay-cross-compiler/gcc-i686/bin/i686-elf-ld -g -relocatable $(FILES) -o ./build/kernelfull.o
	${HOME}/Desktop/samancay-cross-compiler/gcc-i686/bin/i686-elf-gcc -T ./src/linker.ld -o ./bin/kernel.bin -ffreestanding -O0 -nostdlib ./build/kernelfull.o

./bin/boot.bin: ./src/boot/boot.S
	nasm -f bin ./src/boot/boot.S -o ./bin/boot.bin

./build/kernel.S.o: ./src/kernel.S
	nasm -f elf -g ./src/kernel.S -o ./build/kernel.S.o

clean:
	rm -rf ./bin/*.bin
	rm -rf ./build/*.o