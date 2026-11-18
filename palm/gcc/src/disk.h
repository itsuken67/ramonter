//struct prdt_entry {
//	uint32_t phys_addr;
//	uint16_t byte_count;
//	uint16_t flags;
//} __attribute__((packed));

#define DMA_BUFFER_ADDRESS 0xFF000
#define SECTORS_IN_CLUSTER 8
#define BYTES_IN_SECTOR 512
 //4096 bytes before kernel
uint8_t disk_buffer[4096];
//
//struct prdt_entry prdt = {
//	.phys_addr = (uint32_t)DMA_BUFFER_ADDRESS,
//	.byte_count = 512,
//	.flags = 0x8000
//};


void floppy_wait_irq() {
	while ((inb(0x3F4) & 0x80) == 0); // Ждём RQM=1 (готовность)
}

void floppy_calibrate() {
	outb(0x3F5, 0x07); // Команда CALIBRATE
	outb(0x3F5, 0x00); // Номер привода
	floppy_wait_irq();
}

// Сброс контроллера
void floppy_reset() {
	outb(0x3F2, 0x00); // Выключить мотор + сброс
	outb(0x3F2, 0x1C); // Включить мотор + DMA
	floppy_wait_irq();
}

uint8_t read_sector_pio_floppy(uint32_t _lba, uint32_t _sectors) {
	outb(0x3F2, 0x1C);
	while ((inb(0x3F4) & 0xC0) != 0x80);

	char* address = disk_buffer;
	while (_sectors > 0) {

		outb(0x3F5, 0x66); // multiread

		outb(0x3F5, (_lba % 36) / 18); // head
		outb(0x3F5, (_lba % 36)); // cylinder
		outb(0x3F5, (_lba % 18) + 1); // sector

		uint8_t reading = (18 - (_lba % 18));
		if (reading > _sectors)
			reading = _sectors;
		outb(0x3F5, reading); // sector

		while (!(inb(0x3F4) & 0x80));

		__asm volatile(
		"rep insw"
			:
		: "D"(address), "d"(0x3F0), "c"(BYTES_IN_SECTOR / 2)
			: "memory"
			);

		//if (inb(0x3F5) != 0) return -2;
		_sectors -= reading;
		_lba += reading;
		address += reading * BYTES_IN_SECTOR;
	}
	print("read\n");
	print(disk_buffer);
	return 0;
}


uint8_t write_sector_pio_floppy(uint32_t _lba, uint32_t _sectors) {
	outb(0x3F2, 0x1C);  // Включить мотор, выбрать дисковод 0
	for (volatile int i = 0; i < 500000; i++);  // Задержка (~300ms)


	char* address = disk_buffer;
	while (_sectors > 0) {
		print_dword(_lba);
		print_char(' ');
		outb(0x3F5, 0x08); // reset
		inb(0x3F5);
		inb(0x3F5);
		inb(0x3F5);
		inb(0x3F5);
		uint32_t timeout = 100000;
		while ((inb(0x3F4) & 0x80 == 0)) {
			if (--timeout == 0) {
				outb(0x3F2, 0x0C);
				return -1;
			}
		}
		outb(0x3F5, 0x45); // write

		outb(0x3F5, (_lba % 36) / 18); // head
		outb(0x3F5, (_lba / 36)); // cylinder
		outb(0x3F5, (_lba % 18) + 1); // sector
		outb(0x3F5, 2); // sector size

		while ((inb(0x3F4) & 0x80 == 0));

		__asm volatile(
		"rep outsw"
			:
		: "D"(address), "d"(0x3F0), "c"(BYTES_IN_SECTOR / 2)
			: "memory"
			);

		if (inb(0x3F5) & 0xC0) return -5;
		_sectors--;
		_lba++;
		address += BYTES_IN_SECTOR;

	}
	print("wrote\n");
	outb(0x3F2, 0x0C);
	return 0;
}

#define DATA_AREA_BEGIN 33
inline void read_cluster_floppy(uint16_t _cluster) {
	read_sector_pio_floppy(_cluster * SECTORS_IN_CLUSTER + DATA_AREA_BEGIN, SECTORS_IN_CLUSTER);
}

inline void write_cluster_floppy(uint16_t _cluster) {
	write_sector_pio_floppy(_cluster * SECTORS_IN_CLUSTER + DATA_AREA_BEGIN, SECTORS_IN_CLUSTER);
}

void ide_identify() {
	outb(0x1F6, 0xA0); // Выбор Master-диска (LBA)
	outb(0x1F2, 0x00); // Нет секторов для PIO
	outb(0x1F3, 0x00); // LBA low
	outb(0x1F4, 0x00); // LBA mid
	outb(0x1F5, 0x00); // LBA high
	outb(0x1F7, 0xEC); // Команда IDENTIFY

	// Ожидание готовности
	while ((inb(0x1F7) & 0x80) != 0); // BSY=0
	while ((inb(0x1F7) & 0x08) == 0); // DRQ=1

	//Чтение 256 слов (512 байт)
	asm volatile(
		"movw $0x1F0, %%dx\n"
		"movl $256, %%ecx\n"
		"rep insw\n"
		:
	: "D"(disk_buffer)
		: "memory"
		);
}

uint8_t read_sector_pio(uint32_t _lba, uint8_t _sectors) {
	outb(0x1F6, 0xE0 | ((_lba >> 24) & 0x0F));
	outb(0x1F2, _sectors);
	outb(0x1F3, (uint8_t)_lba);
	outb(0x1F4, (uint8_t)(_lba >> 8));
	outb(0x1F5, (uint8_t)(_lba >> 16));
	outb(0x1F7, 0x20); // READ PIO

	uint8_t wait_ready;
	do
	{
		wait_ready = inb(0x1F7);
	} while (wait_ready & 0x80 || !(wait_ready & 0x08));

	__asm volatile(
		"rep insw"
		:
		: "D"(disk_buffer), "d"(0x1F0), "c"(256)
		: "memory"
		);

	//print("Sector successfully read\n");
}

uint8_t write_sector_pio(uint32_t _lba, uint8_t _sectors) {
	outb(0x1F6, 0xE0 | ((_lba >> 24) & 0x0F));
	outb(0x1F2, _sectors);
	outb(0x1F3, (uint8_t)_lba);
	outb(0x1F4, (uint8_t)(_lba >> 8));
	outb(0x1F5, (uint8_t)(_lba >> 16));
	outb(0x1F7, 0x30); // WRITE PIO

	while ((inb(0x1F7) & 0x08) == 0);

	asm volatile(
		"movw $0x1F0, %%dx\n"
		"movl $256, %%ecx\n"
		"rep outsw\n"
		:
		: "S"(disk_buffer)
		: "memory"
		);


	/*for (int i = 0; i < 256; ++i) {
		outw(0x1F0, disk_buffer[i]);
	}*/

	while (inb(0x1F7) & 0x80);

}

//uint8_t read_sector_dma(uint32_t _lba) {
//	outl(0x1F0, (uint32_t)&prdt); // Для Bus-Mastering DMA (PCI IDE)
//	outb(0x1F6, 0xE0 | ((_lba >> 24) & 0x0F));
//	outb(0x1F2, 1);
//	outb(0x1F3, (uint8_t)_lba);
//	outb(0x1F4, (uint8_t)(_lba >> 8));
//	outb(0x1F5, (uint8_t)(_lba >> 16));
//	outb(0x1F7, 0xC8); // READ DMA
//}
//
//uint8_t write_sector_dma(uint32_t _lba) {
//	outl(0x1F0, (uint32_t)&prdt); // Для Bus-Mastering DMA (PCI IDE)
//	outb(0x1F6, 0xE0 | ((_lba >> 24) & 0x0F));
//	outb(0x1F2, 1);
//	outb(0x1F3, (uint8_t)_lba);
//	outb(0x1F4, (uint8_t)(_lba >> 8));
//	outb(0x1F5, (uint8_t)(_lba >> 16));
//	outb(0x1F7, 0xCA); // WRITE DMA
//}

#define FAT32
//#undef FAT32

#ifdef  FAT32
struct BPBHeader {
	uint8_t jmp[3];
	uint8_t OEMLabel[8];
	uint16_t BytesPerSector;
	uint8_t SectorsPerCluster;
	uint16_t ReservedSectors;
	uint8_t FATCopies;
	uint16_t RootDirEntries;
	uint16_t TotalSectors;
	uint8_t MediaDescriptor;
	uint16_t SectorsPerFAT;
	uint16_t SectorsPerTrack;
	uint16_t Heads;
	uint32_t HiddenSectors;
	uint32_t TotalSectors32;
} __attribute__((packed));

struct ExtBPBHeader {
	uint8_t DriveNumber; //     db 0; Номер диска
	uint8_t	Reserved; //        db 0; Зарезервировано
	uint8_t	Signature; //       db 0x29; Сигнатура
	uint32_t	VolumeID; //        dd 0x12345678; ID тома
	uint8_t	VolumeLabel[11]; //     db "MYOS VOLUME"; Метка тома(11 байт)
	uint8_t	FileSystem[8]; //      db "FAT12   "; Тип ФС(8 байт)
} __attribute__((packed));


uint8_t read_cluster(uint32_t _lba, void* _dest) {
	read_sector_pio(_lba, SECTORS_IN_CLUSTER);
	memcpy(&disk_buffer, _dest, SECTORS_IN_CLUSTER * BYTES_IN_SECTOR);
}

uint8_t write_cluster() {

}

#endif //  FAT32

uint8_t format_FAT12_1_44() {
	struct BPBHeader* bpb_header = (struct BPBHeader*)&disk_buffer;
	struct ExtBPBHeader* ext_bpb_header = (struct ExtBPBHeader*)(& disk_buffer + sizeof(*bpb_header));
	
	memcpy("\xeb\x42\x90", bpb_header->jmp, 8);
	memcpy("RAMONTER", bpb_header->OEMLabel, 8);
	bpb_header->BytesPerSector = BYTES_IN_SECTOR;
	bpb_header->SectorsPerCluster = SECTORS_IN_CLUSTER; // 512 * 8 = 4096 bytes
	bpb_header->ReservedSectors = 1;
	bpb_header->FATCopies = 2;
	bpb_header->TotalSectors = 2880; // for 1.44
	bpb_header->MediaDescriptor = 0xF0;
	bpb_header->SectorsPerFAT = 8; // for 1.44
	bpb_header->SectorsPerTrack = 18; // for 1.44
	bpb_header->Heads = 2; // for 1.44
	bpb_header->HiddenSectors = 0;
	bpb_header->TotalSectors32 = 0;

	ext_bpb_header->DriveNumber = 0;
	ext_bpb_header->Reserved = 0;
	ext_bpb_header->Signature = 0x29;
	ext_bpb_header->VolumeID = 0xDDDDDDDD;
	memcpy("FLOPPY 1.44", ext_bpb_header->VolumeLabel, 11);
	memcpy("FAT12   ", ext_bpb_header->FileSystem, 8);
	
}



