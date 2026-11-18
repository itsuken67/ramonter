
static char BUFFER[256];

extern int strlen(const char* _str) {
	int len = 0;
	while (_str[len]) len++;
	return len;
}

inline print_ascii_byte(uint8_t _byte, uint16_t _xpos, uint16_t _ypos) {

}


static inline void shift_screen() {
	asm("1:\n"
		"lodsl\n"
		"stosl\n"
		"loop 1b\n"
		"xorl %%eax, %%eax\n"
		"movl $40, %%ecx\n"
		"rep stosl\n"
		:
		: "S"(VIDEO_ADDRESS + SCREEN_WIDTH * 4), "D"(VIDEO_ADDRESS + SCREEN_WIDTH * 2), "c"((SCREEN_WIDTH * (SCREEN_HEIGHT - 2)) >> 1)
		: "memory"
		);

}


inline void print_pos(char* _str, uint16_t _xpos, uint16_t _ypos) {
	volatile char* video = (volatile char*)(VIDEO_ADDRESS + ((_xpos + _ypos * SCREEN_WIDTH) * 2));
	while (*_str) {
		*video = *_str++;
		video += 2;
	}
}

static short cursor_pos = 0; // Глобальная переменная для позиции курсора

char ascii_number[] = "\0\0\0\0\0";

inline void byte_to_ascii(uint8_t _byte) {
	for (int i = 0; i < 3; ++i) {
		ascii_number[2 - i] = _byte % 10 + '0';
		_byte /= 10;
	}
	ascii_number[3] = '\0';
}


inline void word_to_ascii(uint16_t _word) {
	for (int i = 0; i < 5; ++i) {
		ascii_number[4 - i] = _word % 10 + '0';
		_word /= 10;
	}
}

void print_byte(uint16_t _byte, uint16_t _xpos, uint16_t _ypos) {
	byte_to_ascii(_byte);
	print_pos(ascii_number, _xpos, _ypos);
}

void print_word(uint16_t _word, uint16_t _xpos, uint16_t _ypos) {
	word_to_ascii(_word);
	print_pos(ascii_number, _xpos, _ypos);
}


void move_cursor() {
	outb(CRT_INDEX, 0x0F);
	outb(CRT_DATA, (char)cursor_pos);
	outb(CRT_INDEX, 0x0E);
	outb(CRT_DATA, (char)(cursor_pos >> 8));
	word_to_ascii(cursor_pos);
	print_pos(ascii_number, 75, 0);
}

void print_char(char _char) {

}

void print(char* _str) {
	if ((int)_str < 0x1000) { // Защита от NULL-указателей
		return;
	}
	volatile char* const video = (volatile char*)VIDEO_ADDRESS;

	while (*_str) {
		if (*_str == '\n') {
			cursor_pos = 80 * (cursor_pos / 80 + 1);
			_str++;
			continue;
		}
		if (*_str == BACKSPACE) {
			video[--cursor_pos * 2] = '\0';
			_str++;
			continue;
		}

		if (cursor_pos >= SCREEN_WIDTH * 25) {
			// Прокрутка экрана или сброс позиции
			shift_screen();
			cursor_pos = SCREEN_WIDTH * (SCREEN_HEIGHT - 1);
		}

		video[cursor_pos * 2] = *_str++;     // Символ
		video[cursor_pos * 2 + 1] = 0x07;
		cursor_pos++;
	}
	if (cursor_pos >= SCREEN_WIDTH * 25) {
		// Прокрутка экрана или сброс позиции
		shift_screen();
		cursor_pos = SCREEN_WIDTH * (SCREEN_HEIGHT - 1);
	}
	move_cursor();
}



uint8_t symbols = 0;
void store_got_symbol(char symbol) {
	if (symbol == BACKSPACE && symbols)
		BUFFER[--symbols] = '\0';
	else if (symbols <= 255)
		BUFFER[symbols++] = symbol;

	print(symbol);
	print_byte(symbols, 7, 0);
}


static char* get() {
	is_get_called = 1;
	asm volatile (
		"xorl %%eax, %%eax\n"
		"movl %%ecx, 64\n"
		"rep stosl\n"
		:
		: "D"(BUFFER)
		: "memory"
		);
	while (is_get_called);
	return BUFFER;
}