[bits 32]

global _shell_OFF
_shell_OFF:

    mov dx, 0x604       ; Bochs power management port
    mov ax, 0x2000      ; Shutdown command
    out dx, ax
    
    mov dx, 0xB004      ; Bochs/QEMU legacy shutdown port
    mov ax, 0x2000      ; Shutdown command
    out dx, ax
    
    mov dx, 0x4004      ; Альтернативный порт для QEMU
    mov ax, 0x3400      ; Magic shutdown value
    out dx, ax
    ret