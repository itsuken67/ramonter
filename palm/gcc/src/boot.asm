[bits 16]
[org 0x7C00]
section .text
jmp short _start
nop


OEMLabel        db "RAMONTER" 
BytesPerSector  dw 512     
SectorsPerCluster db 1  
ReservedSectors dw 1    
FATCopies       db 2           ; Количество копий FAT
RootDirEntries  dw 224         ; Записей в корневом каталоге
TotalSectors    dw 2880         ; Всего секторов (1.44 МБ дискета)
MediaDescriptor db 0xF0        ; Дескриптор носителя
SectorsPerFAT   dw 9           ; Секторов на FAT
SectorsPerTrack dw 18          ; Секторов на дорожку
Heads           dw 2           ; Количество головок
HiddenSectors   dd 0           ; Скрытых секторов
LargeSectors    dd 0           ; Больших секторов (если TotalSectors = 0)

; Расширенный BPB
DriveNumber     db 0           ; Номер диска
Reserved        db 0           ; Зарезервировано
Signature       db 0x29        ; Сигнатура
VolumeID        dd 0x12345678  ; ID тома
VolumeLabel     db "FLOPPY 1.44"; Метка тома (11 байт)
FileSystem      db "FAT12   "  ; Тип ФС (8 байт)


_start:
    	cli
    	xor 		ax, ax
    	mov 		ds, ax
    	mov 		es, ax
    	mov 		ss, ax
    	mov 		sp, 0x7C00

	
	mov 		al, 3
	int 		10h
	mov 		dh, 0
	mov 		dl, 0
	xor 		bh, bh
	int 		10h

;mov ax, 0x4F02       ; Функция VBE "установить видеорежим"
 ;   mov bx, 0x4115       | 0x4000  ; Режим 0x115 (800x600x32) + LFB
 ;   int 0x10
	

	
	
	
	
	
	

		
	
	

    ; Загрузка ядра с диска (пример для 1 сектора)
	mov 		dl, 0
    	mov 		ax, 0FFFFh
    	mov 		es, ax
    	mov 		ah, 0x02
    	mov 		al, 3      ; Количество секторов
    	mov 		ch, 0      ; Цилиндр
    	mov 		cl, 16      ; Сектор (следующий после загрузчика)
    	mov 		dh, 1      ; Головка
    	mov 		bx, 0x0010 ; Адрес загрузки (ES:BX = 0xFFFF:0x0010)	

    	int 0x13


	mov 		dl, 0
    	mov 		ax, 0FFFFh
    	mov 		es, ax
    	mov 		ah, 0x02
    	mov 		al, 18      ; Количество секторов
    	mov 		ch, 1      ; Цилиндр
    	mov 		cl, 1      ; Сектор
    	mov 		dh, 0      ; Головка
    	mov 		bx, 0x0610 ; Адрес загрузки (ES:BX = 0xFFFF:0x0010)	

    	int 0x13



	mov 		dl, 0
    	mov 		ax, 0FFFFh
    	mov 		es, ax
    	mov 		ah, 0x02
    	mov 		al, 18      ; Количество секторов
    	mov 		ch, 1      ; Цилиндр
    	mov 		cl, 1      ; Сектор
    	mov 		dh, 1      ; Головка
    	mov 		bx, 0x2810 ; Адрес загрузки (ES:BX = 0xFFFF:0x0010)	

    	int 0x13



    ; Переход в 32-битный режим 
    	lgdt 		[gdt_descriptor]
    	mov 		eax, cr0
    	or	 	eax, 1
    	mov 		cr0, eax

enable_sse:
    	mov	 	eax, cr0
    	and 		ax, 0xFFFB  ; Clear CR0.EM
    	or 		ax, 0x2      ; Set CR0.MP
    	mov 		cr0, eax
    	mov 		eax, cr4
    	or 		ax, 0x600    ; Set CR4.OSFXSR | CR4.OSXMMEXCPT
    	mov 		cr4, eax

protected_mode:
    ; Настроить сегменты данных (DS, ES, SS) на дескриптор данных из GDT
    	mov 		ax, 0x10    ; Селектор дескриптора данных (смещение 16 байт в GDT)
    	mov 		ds, ax
    	mov 		es, ax
    	mov 		fs, ax
    	mov 		gs, ax
    	mov 		ss, ax
    	mov 		esp, 0x90000  ; Стек в 576 КБ
	mov 		ebp, esp
    ; Передать управление в C-код

	jmp 		dword 0x8:0x100000 + KERNEL_MAIN_OFFSET ;_kernel_main    ;
	

error:
	cli
	hlt


; #### STACK ####
; #### LBA ####
[bits 32]
sectors equ 1
FLOPPY_DOR equ 0x3F2
FLOPPY_MSR equ 0x3F4
FLOPPY_FIFO equ 0x3F5
FLOPPY_CTRL equ 0x3F7
DMA_ADDR equ 0x04
DMA_COUNT equ 0x05
DMA_PAGE equ 0x81
DMA_MODE equ 0x0B
DMA_CLEAR equ 0x0C


	

	
	


; Сама GDT
gdt_start:
gdt_null:  ; Нулевой дескриптор (обязательный)
   	dd 		0
    	dd 		0

gdt_code:  ; Сегмент кода
    	dw 		0xFFFF     ; Limit (0-15)
    	dw 		0x0000     ; Base (0-15)
    	db 		0x00       ; Base (16-23)
    	db 		10011010b  ; P=1, DPL=00, S=1, Type=1010 (Code, Exec/Read)
    	db 		11001111b  ; G=1, D/B=1, L=0, Limit (16-19)=1111
    	db 		0x00       ; Base (24-31)

gdt_data:  ; Сегмент данных
    	dw 		0xFFFF     ; Limit
    	dw 		0x0000     ; Base
    	db 		0x00       ; Base
    	db 		10010010b  ; Type=0010 (Data, Read/Write)
    	db 		11001111b  ; Флаги
    	db 		0x00       ; Base

gdt_end:

gdt_descriptor:
    	dw 		gdt_end - gdt_start - 1  ; Размер GDT
    	dd 		gdt_start                 ; Адрес GDT
	

times 510 - ($ - $$) db 0
dw 0xAA55