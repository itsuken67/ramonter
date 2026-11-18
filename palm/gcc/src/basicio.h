#pragma once
#include <stdarg.h>
#define BUFFER_SIZE 256


int argc;
char* argv[BUFFER_SIZE / 2];

int atoi(char* _ascii)
{
	int n = 0;
	while (*_ascii >= '0' && *_ascii <= '9') {
		n *= 10;
		n += *_ascii++;
		n -= '0';
	}
	return n;
}

int strlen(const char* _str) {
	int len = 0;
	while (_str[len]) len++;
	return len;
}

inline void print_pos(char* _str, uint16_t _xpos, uint16_t _ypos) {
	volatile char* video = (volatile char*)(VIDEO_ADDRESS + ((_xpos + _ypos * SCREEN_WIDTH) * 2));
	while (*_str) {
		*video = *_str++;
		video += 2;
	}
}

static void shift_screen() {
	asm("1:\n"
		"lodsl\n"
		"stosl\n"
		"loop 1b\n"
		"movl $0x07000700, %%eax\n"
		"movl $40, %%ecx\n"
		"rep stosl\n"
		:
	: "S"(VIDEO_ADDRESS + SCREEN_WIDTH * 4), "D"(VIDEO_ADDRESS + SCREEN_WIDTH * 2), "c"((SCREEN_WIDTH * (SCREEN_HEIGHT - 2)) >> 1)
		: "memory"
		);

}



static short cursor_pos = 0; // Глобальная переменная для позиции курсора

char ascii_number[] = "\0\0\0\0\0\0\0\0\0\0";
char* ascii_number_ptr;

// BYTE

void byte_to_ascii(uint8_t _byte) {
	ascii_number_ptr = ascii_number;
	for (int i = 0; i < 3; ++i) {
		ascii_number[2 - i] = _byte % 10 + '0';
		_byte /= 10;
		if (!_byte) {
			ascii_number_ptr += 2 - i;
			break;
		}
	}
	ascii_number[3] = '\0';
}

inline void print_byte_pos_inline(uint8_t _byte, uint16_t _xpos, uint16_t _ypos) {
	byte_to_ascii(_byte);
	print_pos(ascii_number_ptr, _xpos, _ypos);
}

void print_byte_pos(uint8_t _byte, uint16_t _xpos, uint16_t _ypos) {
	print_byte_pos_inline(_byte, _xpos, _ypos);
}

void print_byte(uint8_t _byte) {
	byte_to_ascii(_byte);
	print(ascii_number_ptr);
}

// WORD

void word_to_ascii(uint16_t _word) {

	ascii_number_ptr = ascii_number;
	for (int i = 0; i < 5; ++i) {
		ascii_number[4 - i] = _word % 10 + '0';
		_word /= 10;
		if (!_word) {
			ascii_number_ptr += 4 - i;
			return;
		}
	}
	ascii_number[5] = '\0';
}

inline void print_word_pos_inline(uint16_t _word, uint16_t _xpos, uint16_t _ypos) {
	word_to_ascii(_word);
	print_pos(ascii_number_ptr, _xpos, _ypos);
}

void print_word_pos(uint16_t _word, uint16_t _xpos, uint16_t _ypos) {
	print_word_pos_inline(_word, _xpos, _ypos);
}

void print_word(uint16_t _word) {
	word_to_ascii(_word);
	print(ascii_number_ptr);
}

// DWORD

void dword_to_ascii(uint32_t _dword) {

	ascii_number_ptr = ascii_number;
	for (int i = 0; i < 10; ++i) {
		ascii_number[9 - i] = _dword % 10 + '0';
		_dword /= 10;
		if (!_dword) {
			ascii_number_ptr += 9 - i;
			return;
		}
	}
}

inline void print_dword_pos_inline(uint32_t _dword, uint16_t _xpos, uint16_t _ypos) {
	dword_to_ascii(_dword);
	print_pos(ascii_number_ptr, _xpos, _ypos);
}

void print_dword_pos(uint32_t _dword, uint16_t _xpos, uint16_t _ypos) {
	print_dword_pos_inline(_dword, _xpos, _ypos);
}

void print_dword(uint32_t _dword) {
	dword_to_ascii(_dword);
	print(ascii_number_ptr);
}



void move_cursor() {
	outb(CRT_INDEX, 0x0F);
	outb(CRT_DATA, (char)cursor_pos);
	outb(CRT_INDEX, 0x0E);
	outb(CRT_DATA, (char)(cursor_pos >> 8));
}


static inline void delay(int _how_long) {
	for (int i = 0; i < 10000 * _how_long; ++i) {
		__asm__ volatile ("nop");
	}
}

static inline void print_char_inline(char _char, char _col) {
	volatile char* const video = (volatile char*)VIDEO_ADDRESS;
	if (_char == '\n') {
		cursor_pos = 80 * (cursor_pos / 80 + 1);
		delay(100);
		move_cursor();
		goto print_char_n;
	}
	if (_char == '\t') {
		cursor_pos = (cursor_pos & 0xFFFC) + 0x4;
		goto print_char_n;
	}
	if (_char == BACKSPACE && cursor_pos >= 80) {
		video[--cursor_pos * 2] = '\0';
		return;
	}

	video[cursor_pos * 2] = _char;     // Символ
	if (_col != 0x07)
		video[cursor_pos * 2 + 1] = _col;     // Символ
	cursor_pos++;

print_char_n:
	if (cursor_pos >= SCREEN_WIDTH * 25) {
		// Прокрутка экрана или сброс позиции
		shift_screen();
		cursor_pos = SCREEN_WIDTH * (SCREEN_HEIGHT - 1);
	}

}

static inline void print_char_formatted_inline(char _char, char _col) {
	print_char_inline(_char, _col);
}

void print_char(char _char) {
	print_char_formatted_inline(_char, 0x07);
}

void print_char_formatted(char _char, char _col) {
	print_char_formatted_inline(_char, _col);
}


void print_formatted(char* _str) {
	if ((int)_str < 0x1000) { // Защита от NULL-указателей
		return;
	}
	while (*_str) {
		print_char_formatted(*_str++, *_str++);
	}
	move_cursor();
}

// basic one-colour print
void print(char* _str) {
	if ((int)_str < 0x1000) { // Защита от NULL-указателей
		return;
	}
	while (*_str) {
		print_char_inline(*_str++, 0x07);
	}
	move_cursor();
}

void print_count(char* _str, int _count) {
	if ((int)_str < 0x1000) { // Защита от NULL-указателей
		return;
	}
	while (_count--) {
		print_char(*_str++);
	}
	move_cursor();
}

void print_until_space(char* _str) {
	if ((int)_str < 0x1000) { // Защита от NULL-указателей
		return;
	}
	while (*_str != ' ' && *_str) {
		print_char(*_str++);
	}
	move_cursor();
}


// optimizing all these print functions into one
void printf(char* _str, ...) {
	va_list list;
	va_end(list);

	if ((int)_str < 0x1000) { // Защита от NULL-указателей
		return;
	}
	while (*_str) {
		if (_str)
		print_char_inline(*_str++, 0x07);
	}
	move_cursor();
}


//void printf(char* str, ...)
//{
//	// initializing list pointer
//	va_list ptr;
//	va_start(ptr, str);
//
//	// char array to store token
//	char token[1000];
//	// index of where to store the characters of str in
//	// token
//	int k = 0;
//
//	// parsing the formatted string
//	for (int i = 0; str[i] != '\0'; i++) {
//		token[k++] = str[i];
//
//		if (str[i + 1] == '%' || str[i + 1] == '\0') {
//			token[k] = '\0';
//			k = 0;
//			if (token[0] != '%') {
//				fprintf(stdout, "%s", token); // printing the whole token if
//				// it is not a format specifier
//			}
//			else {
//				int j = 1;
//				char ch1 = 0;
//
//				// this loop is required when printing
//				// formatted value like 0.2f, when ch1='f'
//				// loop ends
//				while ((ch1 = token[j++]) < 58) {
//				}
//				// for integers
//				if (ch1 == 'i' || ch1 == 'd' || ch1 == 'u'
//					|| ch1 == 'h') {
//					fprintf(stdout, token, va_arg(ptr, int));
//				}
//				// for characters
//				else if (ch1 == 'c') {
//					fprintf(stdout, token, va_arg(ptr, int));
//				}
//				// for float values
//				else if (ch1 == 'f') {
//					fprintf(stdout, token, va_arg(ptr, double));
//				}
//				else if (ch1 == 'l') {
//					char ch2 = token[2];
//
//					// for long int
//					if (ch2 == 'u' || ch2 == 'd'
//						|| ch2 == 'i') {
//						fprintf(stdout, token, va_arg(ptr, long));
//					}
//
//					// for double
//					else if (ch2 == 'f') {
//						fprintf(stdout, token, va_arg(ptr, double));
//					}
//				}
//				else if (ch1 == 'L') {
//					char ch2 = token[2];
//
//					// for long long int
//					if (ch2 == 'u' || ch2 == 'd'
//						|| ch2 == 'i') {
//						fprintf(stdout, token, va_arg(ptr, long long));
//					}
//
//					// for long double
//					else if (ch2 == 'f') {
//						fprintf(stdout, token, va_arg(ptr, long double));
//					}
//				}
//
//				// for strings
//				else if (ch1 == 's') {
//					fprintf(stdout, token, va_arg(ptr, char*));
//				}
//
//				// print the whole token
//				// if no case is matched
//				else {
//					fprintf(stdout, "%s", token);
//				}
//			}
//		}
//	}
//
//	// ending traversal
//	va_end(ptr);
//}


uint8_t symbols = 0;
bool symbols_refresh;
void store_got_symbol(char symbol) {
	if (symbol == BACKSPACE)
		if (symbols)
			BUFFER[--symbols] = '\0';
		else return;
	else if (symbols < BUFFER_SIZE - 1)
		BUFFER[symbols++] = symbol;
	else return;

	print_char(symbol);
	print_pos("   ", SYMBOLS_OUTPUT_POS, 0);
	print_byte_pos(symbols, SYMBOLS_OUTPUT_POS, 0);
	move_cursor();
}


char* get() {
	is_get_called = true;
	symbols = 0;
	asm volatile (
		"xorl %%eax, %%eax\n"
		"movl $64, %%ecx\n"
		"rep stosl\n"
		:
		: "D"(BUFFER)
		: "memory"
		);
	while (is_get_called)
		asm("pause");
	print_char('\n');
	move_cursor();
	return BUFFER;
}

void parse() {
	argc = 0;
	bool is_arg = false;
	uint8_t i = 0;
	while (BUFFER[i]) {
		if (BUFFER[i] != ' ') {
			if (!is_arg) {
				argv[argc++] = BUFFER + i;
				is_arg = true;
			}
		}
		else {
			is_arg = false;
		}
		i++;
	}
}

inline void get_parsed_line() {
	get();
	parse();
}