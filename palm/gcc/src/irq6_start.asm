[bits 32]
global _irq6_init
extern _irq6_handler

_irq6_init:
	call _irq6_handler
	iretd