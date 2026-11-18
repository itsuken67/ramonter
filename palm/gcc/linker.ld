ENTRY(_kernel_main)  /* Точка входа в C-коде */
STACK_SIZE = 0x4000;  /* 16KB стека */

SECTIONS {
    . = 0x100000;  /* Ядро загружается по адресу 1 МБ */
    .text : { 
		*(.text) 
		*(.rdata*)
} 

    .data : { *(.data) }

    .bss : { *(.bss) }

    /DISCARD/ : { *(.eh_frame) *(.comment) *(.reloc .reloc.*)}
}