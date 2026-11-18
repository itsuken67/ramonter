ENTRY(kernel_main)  /* Точка входа в C-коде */
STACK_SIZE = 0x4000;  /* 16KB стека */

.stack : {
    . = ALIGN(4);
    _stack_bottom = .;
    . += STACK_SIZE;
    _stack_top = .;
}

SECTIONS {
    . = 0x1000;  /* Ядро загружается по адресу 1 МБ */
    .text : { 
		*(.text) 
		*(.rdata*)
} 

    .data : { *(.data) }

    .bss : { *(.bss) }
    /DISCARD/ : { *(.eh_frame) *(.comment) }
}