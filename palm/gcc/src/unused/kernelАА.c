#define VIDEO_ADDRESS 0xB8000
#define SCREEN_WIDTH 80
#define SCREEN_HEIGHT 25
#define CRT_INDEX 0x3D4
#define CRT_DATA 0x3D5
#include <stdint.h>
#include "cpu.h"
#include "basicio.h"

static char BUFFER[256];
static char* get() {

	return BUFFER;
}

extern int strlen(const char* str) {
    int len = 0;
    while(str[len]) len++;
    return len;
}

static inline void shift_screen() {
	asm volatile ("1:\n"
			"lodsl\n"
			"stosl\n"
			"loop 1b\n"
			"xorl %%eax, %%eax\n"
			"movl $40, %%ecx\n"
			"rep stosl\n"
							:
							: "S"(VIDEO_ADDRESS + SCREEN_WIDTH * 2 + 80 * 2), "D"(VIDEO_ADDRESS + 80 * 2), "c"((SCREEN_WIDTH * (SCREEN_HEIGHT - 2)) >> 1)
							: "memory"
							);
	
}


static short cursor_pos = 80; // Глобальная переменная для позиции курсора

char ascii_number[] = "\0\0\0\0\0";
void byte_to_ascii(uint16_t word) {
	for (int i = 0; i < 5; ++i) {
		ascii_number[4 - i] = word % 10 + '0';
		word /= 10;
	}
}

inline void print_pos(char* str, uint16_t xpos, uint16_t ypos) {
	volatile char* video = (volatile char*)(VIDEO_ADDRESS + ((xpos + ypos * SCREEN_WIDTH) * 2));
	while (*str) {
		*video = *str++;
		video += 2;
	}
}

void move_cursor() {
	outb(CRT_INDEX, 0x0F);
	outb(CRT_DATA, (char)cursor_pos);
	outb(CRT_INDEX, 0x0E);
	outb(CRT_DATA, (char)(((cursor_pos >> 8) & 0xF)));
	byte_to_ascii(cursor_pos);
	print_pos(ascii_number, 75, 0);
}

void print(char* str) {
	if((int)str < 0x1000) { // Защита от NULL-указателей
        return;
    }
    volatile char* const video = (volatile char*)(VIDEO_ADDRESS);
	print_pos(str, 4, 0);
    
    while(*str) {
		if (*str == '\n') {
			cursor_pos = 80 * (cursor_pos / 80 + 1);
			str++;
			continue;
		}
        if(cursor_pos >= SCREEN_WIDTH * 25) {
            // Прокрутка экрана или сброс позиции
			shift_screen();
            cursor_pos = SCREEN_WIDTH * (SCREEN_HEIGHT - 1);
        }
        
        video[cursor_pos * 2] = *str++;     // Символ
        video[cursor_pos * 2 + 1] = 0x07;
        cursor_pos++;
    }
        if(cursor_pos >= SCREEN_WIDTH * 25) {
            // Прокрутка экрана или сброс позиции
			shift_screen();
            cursor_pos = SCREEN_WIDTH * (SCREEN_HEIGHT - 1);
        }
	move_cursor();
}


static inline void delay() {
		for (int i = 0; i < 20000000; ++i) {
			__asm__ volatile ("nop");
		}
}



void kernel_main() {
	init_idt();
	init_keyboard();
	move_cursor();


	for (volatile int* video = (volatile int*)(VIDEO_ADDRESS); video < (volatile int*)(VIDEO_ADDRESS + SCREEN_WIDTH * 2); ++video) {
		*video = 0x3B003B00;
	}

    char u[] = "end of program (WRONG).";
	/*print("Hey ther!e!\n");
	char HW[52] = "A\n";
    for (int i = 1; i < 40; ++i) {
		 print(HW);
		 HW[i] = 'A';
		 HW[i+1] = '\n';
		 delay();
	}*/
	print(u);
	move_cursor();
    while (1);
    __asm ("cli\nhlt");
}