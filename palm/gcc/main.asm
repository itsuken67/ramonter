	.file	"main.c"
	.intel_syntax noprefix
	.text
	.globl	_b
	.data
	.align 4
_b:
	.long	42
	.text
	.globl	___main
	.def	___main;	.scl	2;	.type	32;	.endef
___main:
	push	ebp
	mov	ebp, esp
	mov	DWORD PTR _b, 55
	nop
	pop	ebp
	ret
	.ident	"GCC: (GNU) 13.2.0"
