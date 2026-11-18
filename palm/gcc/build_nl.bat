
set NASM_PATH=C:\Users\rifk0\AppData\Local\bin\NASM
set GCC_PATH=C:\Users\rifk0\gcc\bin


%NASM_PATH%\nasm.exe -f elf32 src/isr.asm -o isr.o
%NASM_PATH%\nasm.exe -f elf32 src/syscall_start.asm -o syscall_start.o
%NASM_PATH%\nasm.exe -f elf32 src/shell_off.asm -o shell_off.o
:: 5. Сборка загрузчика
%NASM_PATH%\nasm.exe -f elf32 src/boot.asm -o boot.o
:: 1. Компиляция ядра
%GCC_PATH%\gcc.exe -O1 -mtune=generic -fomit-frame-pointer -march=native -m32 -mno-sse -mno-sse2 -mno-mmx -ffreestanding -nostdlib -c src/kernel.c -o kernel.o
%GCC_PATH%\ld.exe -m i386pe -Ttext 0x100000 -o kernel.elf boot.o isr.o syscall_start.o shell_off.o kernel.o --entry=_kernel_main




:: 6. Объединение загрузчика и ядра
%GCC_PATH%\objcopy.exe -O binary kernel.elf os-image.bin
