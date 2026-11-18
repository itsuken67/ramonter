#define VIDEO_ADDRESS 0xB8000
#define SCREEN_WIDTH 80
#define SCREEN_HEIGHT 25
#define CRT_INDEX 0x3D4
#define CRT_DATA 0x3D5
#include <stdint.h>
#include "cpu.h"
#include "basicio.h"



extern int strlen(const char* str) {
    int len = 0;
    while(str[len]) len++;
    return len;
}

static inline void shift_screen() {
	asm ("1:\n"
			"lodsl\n"
			"stosl\n"
			"loop 1b\n"
			"xorl %%eax, %%eax\n"
			"movl $40, %%ecx\n"
			"rep stosl\n"
							:
							: "S"(VIDEO_ADDRESS + SCREEN_WIDTH * 2), "D"(VIDEO_ADDRESS), "c"((SCREEN_WIDTH * (SCREEN_HEIGHT - 1)) >> 1)
							: "memory"
							);
	
}


static short cursor_pos = 0; // Глобальная переменная для позиции курсора



void move_cursor() {
	while (cursor_pos >= SCREEN_WIDTH * SCREEN_HEIGHT)
		cursor_pos -= SCREEN_WIDTH;
	outb(CRT_INDEX, 0x0F);
	outb(CRT_DATA, (char)cursor_pos);
	outb(CRT_INDEX, 0x0E);
	outb(CRT_DATA, (char)(cursor_pos >> 8));
}

void print(char* str) {
	if((int)str < 0x1000) { // Защита от NULL-указателей
        return;
    }
    volatile char* const video = (volatile char*)VIDEO_ADDRESS;
    
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

static char BUFFER[256];
static char* get() {
	
	return BUFFER;
}

void kernel_main() {
	
	init_idt();
	init_keyboard();
    char u[] = "end of program (WRONG).";
	print("Hey ther!e!\n");
	/*char HW[52] = "A\n";
    for (int i = 1; i < 40; ++i) {
		 print(HW);
		 HW[i] = 'A';
		 HW[i+1] = '\n';
		 delay();
	}*/
	print(u);
    while (1);
    __asm ("cli\nhlt");
}