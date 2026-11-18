#pragma once
#define IRQ1 0x21
#define IRQ2 0x22
#define IRQ3 0x23
#define IRQ4 0x24
#define IRQ5 0x25
#define IRQ6 0x26
#define IRQ7 0x27
#define IRQ8 0x28
#define IRQ9 0x29
#define IRQ10 0x2A
#define IRQ11 0x2B
#define IRQ12 0x2C
#define IRQ13 0x2D
#define IRQ14 0x2E
#define IRQ15 0x2F


#define BACKSPACE 0x0E
#define ENTER 0x1C
#define SHIFT 0x2A
#define release 0x80
#include <stdbool.h>
#define BUFFER_SIZE 256

#define HEX_OUTPUT_XPOS 70
#define SYMBOLS_OUTPUT_POS 77

extern void isr_default();
extern void irq6_init();

void print_pos(char* _str, uint16_t _xpos, uint16_t _ypos);

void print(char* _str);

struct idt_entry {
	uint16_t base_low;
	uint16_t selector;
	uint8_t zero;
	uint8_t flags;
	uint16_t base_high;
} __attribute__((packed));

struct idt_ptr {
	uint16_t limit;
	uint32_t base;
} __attribute__((packed));

struct idt_entry idt[256];
struct idt_ptr idtp;

inline void outb(short _port, char _val) {
	asm volatile (
		"outb %0, %1" : : "a"(_val), "Nd" (_port)
	);
}

inline void outw(short _port, short _val) {
	asm volatile (
		"outw %0, %1" : : "a"(_val), "Nd" (_port)
		);
}

inline void outl (short _port, int _val) {
	asm volatile (
		"outl %0, %1" : : "a"(_val), "Nd" (_port)
		);
}

inline uint8_t inb(uint16_t _port) {
	uint8_t ret;
	asm volatile("inb %1, %0" : "=a"(ret) : "Nd"(_port));
	return ret;
};

inline uint16_t inw(uint16_t _port) {
	uint16_t ret;
	asm volatile("inw %1, %0" : "=a"(ret) : "Nd"(_port));
	return ret;
};

void set_idt_entry(int _num, uint32_t _base, uint16_t _sel, uint8_t _flags) {
	idt[_num].base_low = _base & 0xFFFF;
	idt[_num].base_high = _base >> 16;
	idt[_num].selector = _sel;
	idt[_num].flags = _flags;
	idt[_num].zero = 0;
}

void init_idt() {
	idtp.limit = sizeof(idt) - 1;
	idtp.base = (uint32_t)&idt;
	
	for (int i = 0; i < 256; ++i) {
		set_idt_entry(i, 0, 0x0008, 0x8E);
	}
	
    asm volatile("lidt %0" : : "m"(idtp));
    asm volatile("sti");  // Разрешаем прерывания
}



//extern void isr_default();

void store_got_symbol(char symbol);

void print_char(char _char);
void move_cursor();

static char BUFFER[BUFFER_SIZE];

bool shift_pressed = false;
volatile bool is_get_called = false;

void irq1_handler() {
	static const char scancodes[] = {
        0, 0, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', BACKSPACE,
        0, 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\n',
        0, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '\'',
        0, '\\', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, '*',
        0, ' ', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0, 0, 0, '7', '8', '9', '-', '4', '5',
        '6', '+', '1', '2', '3', '0', '.', 0, 0, 0, 0, 0
    };
	
	static const char scancodes_shift[] = {
        0, 0, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', BACKSPACE,
        0, 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', '\n',
        0, 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '|', '\"',
        0, '\\', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', 0, '*',
        0, ' ', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0, 0, 0, '7', '8', '9', '-', '4', '5',
        '6', '+', '1', '2', '3', '0', '.', 0, 0, 0, 0, 0
    };
	
	uint8_t scancode;
	// getting the scancode
	scancode = inb(0x60);
	
	// output for the ASCII'd scancode
	//volatile char* video = (volatile char*)(VIDEO_ADDRESS);
	// *video = scancode;



	const char hex_letters[] = "0123456789ABCDEF";
	char hex_output[] = "0x00";
	hex_output[3] = hex_letters[scancode & 0xF];
	hex_output[2] = hex_letters[scancode >> 4];
	print_pos(hex_output, HEX_OUTPUT_XPOS, 0);
	



	if (scancode == SHIFT) {
		shift_pressed = 1;
		return;
	}
	if (scancode == SHIFT + release) {
		shift_pressed = 0;
		return;
	}

	// in case of prompting read the Enter scancode to proceed
	if (is_get_called && scancode == ENTER) {
		// finish the "get" function

		is_get_called = 0;
		return;
	}
	
	
	
	// printing the actual letter if possible
	if (is_get_called) {
		if (!(scancode & 0x80)) {
			if (scancode < sizeof(scancodes)) {
				// left shift
				if (shift_pressed)
					scancode = scancodes_shift[scancode];
				else
					scancode = scancodes[scancode];
			}
			store_got_symbol(scancode);
		}
	}
}


void irq6_handler() {
	print("END\n");
	return;
}

#define MASTER_PIC_COMMANDS 0x20
#define SLAVE_PIC_COMMANDS 0xA0
#define MASTER_PIC_DATA 0x21
#define SLAVE_PIC_DATA 0xA1
void pic_remap() {
	// ICW1 
	outb(MASTER_PIC_COMMANDS, 0x11);
	outb(SLAVE_PIC_COMMANDS, 0x11);
	
	// ICW2 (irq offset)
	outb(MASTER_PIC_DATA, 0x20); 
	outb(SLAVE_PIC_DATA, 0x28);
	
	// ICW3 (cascading)
	outb(MASTER_PIC_DATA, 0x04);
	outb(SLAVE_PIC_DATA, 0x02);
	
	// ICW4 (additional)
	outb(MASTER_PIC_DATA, 0x01);
	outb(SLAVE_PIC_DATA, 0x01);
	
	// IRQ mask
	outb(MASTER_PIC_DATA, 0xBD);
	outb(SLAVE_PIC_DATA, 0xFF);
}

void init_keyboard() {
	pic_remap();
	set_idt_entry(IRQ1, (uint32_t)&isr_default,  0x0008, 0x8E);
	print("Keyboard initialized\n");
}

void init_floppy() {
	set_idt_entry(IRQ6, (uint32_t)&irq6_init, 0x0008, 0x8E);
	print("Floppy initialized\n");
}