[bits 32]
global _isr_default
extern _irq1_handler

_isr_default:
	pusha
	call _irq1_handler
	popa
	mov al, 0x20
	out 0x20, al
	iretd
