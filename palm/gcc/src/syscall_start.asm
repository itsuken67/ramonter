[bits 32]
global _syscall_init
extern _syscall_proc

_syscall_init:
	call _syscall_proc
	push ax
	mov al, 0x20
	out 0x20, al
	pop ax
	iretd
