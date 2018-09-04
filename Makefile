NAME=printf

all: printf

clean:
	rm -rf printf printf.o

printf: printf.asm
	nasm -f elf printf.asm
	gcc -g -m32 -o printf printf.o # C Driver /usr/share/csc314/driver.c /usr/share/csc314/asm_io.o
