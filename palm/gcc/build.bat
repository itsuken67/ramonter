@echo off
set NASM_PATH=C:\Users\rifk0\AppData\Local\bin\NASM
set GCC_PATH=C:\Users\rifk0\gcc\bin


%NASM_PATH%\nasm.exe -f elf32 src/isr.asm -o isr.o
%NASM_PATH%\nasm.exe -f elf32 src/syscall_start.asm -o syscall_start.o
%NASM_PATH%\nasm.exe -f elf32 src/irq6_start.asm -o irq6_start.o
%NASM_PATH%\nasm.exe -f elf32 src/shell_off.asm -o shell_off.o
:: 1. Компиляция ядра
%GCC_PATH%\gcc.exe -O1 -Wl,--gc-sections -Wl,--strip-all -Wl,-n -mtune=generic -fomit-frame-pointer -march=native -m32 -mno-sse -mno-sse2 -mno-mmx -ffreestanding -nostdlib -c src/kernel.c -o kernel.o
%GCC_PATH%\ld.exe -m i386pe -Ttext 0x100000 -T linker.ld -o kernel.elf isr.o syscall_start.o irq6_start.o shell_off.o kernel.o --entry=_kernel_main

:: 2. Получаем адрес kernel_main
for /f "tokens=9" %%A in ('%GCC_PATH%\objdump.exe -t kernel.elf ^| find "_kernel_main"') do (
    set KERNEL_MAIN_ADDR=%%A
)

:: 4. Подставляем смещение в загрузчик (генерируем временный файл)
echo KERNEL_MAIN_OFFSET equ %KERNEL_MAIN_ADDR% > boot_defines.asm
copy /b boot_defines.asm + src\boot.asm boot_kernel.asm

:: 5. Сборка загрузчика
%NASM_PATH%\nasm.exe -f bin boot_kernel.asm -o boot.bin

:: 6. Объединение загрузчика и ядра
%GCC_PATH%\objcopy.exe -O binary kernel.elf kernel.bin
del additional.img.lock
FASM to144mb.asm os-image.bin
osimage.bxrc