#define VIDEO_ADDRESS 0xB8000
#define SCREEN_WIDTH 80
#define SCREEN_HEIGHT 25
#define CRT_INDEX 0x3D4
#define CRT_DATA 0x3D5
#include <stdint.h>
#include "memory.h"
#include "cpu.h"
#include "basicio.h"
#include "syscall.h"
#include "disk.h"
#include "shellcommands.h"








inline char to_upper(char _char) {
	if (_char >= 'a')
		return _char - ('a' - 'A');
	else return _char;
}

bool compare_until_space(char* _str1, char* _str2) {
	while (to_upper(*_str1) == *_str2) {
		_str1++;
		if (!*++_str2 && (!*_str1 || *_str1 == ' ')) {
			return true;
		}
	}
	return false;
}

#define commands \
X (FORMAT) \
X (OFF) \
X (ECHO) \
X (ERS) \
X (DISKINFO) \
X (DISK) \
X (RAM) \
X (PRC) \
X (HELP) \
X (DIR)




#define X(com) #com,



void kernel_main() {





	char RMT_VER[] = "Ramonter v0.04 (now in C!)"; 
	//disk_buffer = (volatile uint8_t*)DMA_BUFFER_ADDRESS;
	volatile uint16_t* video = (volatile uint16_t*)(VIDEO_ADDRESS);
	int i = 0;
	// red panel
	for (; i < sizeof(RMT_VER) - 1; ++i) {
		video[i] = 0x4F00;
	}
	// blue panel
	for (; i < SCREEN_WIDTH; ++i) {
		video[i] = 0x1F00;
	}
	cursor_pos = 80;
	print_pos(RMT_VER, 0, 0);
	move_cursor();

	
	init_idt();
	init_keyboard();
	init_floppy();
	initialize_syscalls();


	read_sector_pio_floppy(0, 1);



	char string[] = "0x30 interrupt syscall works!\n";
	syscall(0x03, 0x0, 0x0, (uint32_t)string);


	//ide_identify();
	//uint32_t lba_sectors = *((uint32_t*)&disk_buffer[114]);
	//print("LBA Sectors: ");
	//print_dword(lba_sectors);
	//print_char('\n');


	// Количество секторов (LBA28)
	/*uint32_t lba_sectors;
	i = 0;
	do
	{
		lba_sectors = *((uint32_t*)&disk_buffer[i++]);
		print("LBA Sectors: ");
		print_dword(lba_sectors);
		print_char('\n');
		delay(500);
	} while (lba_sectors != 20160);
	print("Offset: ");
	print_dword(i);
	print_char('\n');*/
	 

	//uint8_t check = write_sector_pio_floppy(0, 1);
	// print_byte((uint8_t)check);
	//if (check)
	//	print("\nERROR WHILE WRITING\n");
	


	//print((char*)syscall(0x04, 0x0, 0x0, 0x0));

	char* COMMANDS[] = { commands};
	while (true) {
	_emergency_exit:
		/*char enter[] = "Enter command: ";
		syscall(0x03, 0x0, 0x0, (uint32_t)enter);*/
		print("Enter command: ");
		get_parsed_line();

		int command_id = 0;
		for (; !compare_until_space(argv[0], COMMANDS[command_id]); ++command_id) {
			if (command_id >= (sizeof(COMMANDS) / sizeof(COMMANDS[0]) - 1)) {
				print("Unknown command!\n");
				goto _emergency_exit;
			}
		}
		switch (command_id)
		{
		case 0:
			shell_FORMAT();
			break;
		case 1:
			shell_OFF();
			print("SHUTDOWN CALLED\n");
			break;
		case 2:
			shell_ECHO();
			break;
		case 3:
			shell_ERS();
			break;
		case 4:
			shell_DISKINFO();
			break;
		case 5:
			shell_DISK();
			break;
		case 6:
			shell_RAM();
			break;
		case 7:
			shell_PRC();
			break;
		case 8:
			shell_HELP();
			break;
		case 9:
			shell_DIR();
			break;
		default:
			break;
		}
		print_char('\n');
	}
 //   char u[] = "end of program (WRONG).";
	//print("Hey ther!e!\n");
	///*char HW[52] = "A\n";
 //   for (int i = 1; i < 40; ++i) {
	//	 print(HW);
	//	 HW[i] = 'A';
	//	 HW[i+1] = '\n';
	//	 delay();
	//}*/
	//print(u);

	// shell cycle
	//while (true) {
	//	print("Enter command: ");
	//	get();
	//	parse();

	//	for (int i = 0; i < argc; ++i) {
	//		print_until_space(argv[i]);
	//		print_char('\n');
	//	}


	//	while (1);
	//	while (1);

	//	// approaching to non-empty content
	//	/*while (BUFFER[offset] == ' ') ++offset;
	//	int command_id = 0;
	//	for (; compare_until_space(BUFFER + offset, COMMANDS[command_id]); ++command_id) {
	//		if (command_id >= sizeof(COMMANDS)) {
	//			print("Unknown command!\n");
	//			goto _emergency_exit;
	//		}
	//	}*/
	//	// now we've got an ID, proceed
	//	


	//}
    while (1);
    __asm ("cli\nhlt");
}