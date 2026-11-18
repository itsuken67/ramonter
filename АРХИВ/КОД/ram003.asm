HEIGHT_T = 25
WIDTH_T = 80
ENDL = 0x0D
END_STR = 0x00

 org 7c00h

start:
cli
xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 07c00h
sti

mov al, 3
int 10h
mov dh, 0
mov dl, 0
xor bh, bh
int 10h


push 0x50
pop es

mov dx, 0 ;disk A, head 0 (dl - disk, dh - head)
mov ch, 0 ;10bit - sector, 6bit - cyl
mov cl, 2 ;sector
mov al, 8
xor bx, bx

mov ah, 02h
int 13h


jmp 0050:0000
jmp $

fd db 'error!'

times 510 - ($-7c00h) db 0
db 055h, 0AAh ;ДАЛЬШЕ ЗАГРУЗЧИК НЕ ИДЁТ







;ПРОГРАММА ВНЕ ЗАГРУЗЧИКА

macro debg
{
	print str_EAXt, 4Fh, 52, 15
	print str_EBXt, 4Fh, 52, 16
	print str_ECXt, 4Fh, 52, 17
	print str_EDXt, 4Fh, 52, 18
	print str_0x, 1Fh, 56, 15
	print str_0x, 1Fh, 56, 16
	print str_0x, 1Fh, 56, 17
	print str_0x, 1Fh, 56, 18
	REGtoHEXsymbs eax, str_EAX
	REGtoHEXsymbs ebx, str_EBX
	REGtoHEXsymbs ecx, str_ECX
	REGtoHEXsymbs edx, str_EDX
	print str_EAX, 1Fh, 58, 15
	print str_EBX, 1Fh, 58, 16
	print str_ECX, 1Fh, 58, 17
	print str_EDX, 1Fh, 58, 18
	
}

macro drawRAM
{
	mov si, bm_RAM
	cmp si, 0
	
}

macro bcd value, rcv
{
	pusha
	mov si, rcv +2
	mov ax, value
	mov bl, 10
	div bl
	push ax
	add ah, 30h
	mov [si], ah
	pop ax
	dec si
	xor ah, ah
	cmp si, rcv - 1
	jne ($ - 16)

;remove_nulls
	mov si, symbol
	mov ah, '0'
	mov al, ' '
	mov cx, 2
	cmp [si], ah
	jne ($ + 6)
	mov [si], al
	inc si
	loop ($ - 9)
	popa
}





macro REGtoHEXsymbs reg, rcv
{
	call SendAll
	push reg
	pop eax
	mov si, rcv + 7
	xor edx, edx
	mov cx, 8
	mov ebx, 16
	div ebx
	cmp dl, 10
	jl ($ + 4)
	add dl, 07h ;БУКВЫ
	add dl, 30h
	mov [si], dl
	dec si
	xor dl, dl
	loop ($ - 19) ;div ebx
	call GetAll
}

macro word_to_hex word, rcv
{
	call SendAll
	mov si, rcv + 3
	mov ax, word
	xor dx, dx
	mov cx, 4
	mov bx, 16
	div bx
	cmp dl, 10
	jl ($ + 4)
	add dl, 07h ;БУКВЫ
	add dl, 30h
	mov [si], dl
	dec si
	xor dl, dl
	loop ($ - 18) ;div ebx
	call GetAll
}

macro byte_to_hex byte, rcv
{
	call SendAll
	mov si, byte 
	mov al, [si]
	mov si, rcv
	inc si
	xor ah, ah
	mov cx, 2
	mov bl, 16
	div bl
	cmp ah, 10
	jl ($ + 4)
	add ah, 07h ;БУКВЫ
	add ah, 30h
	mov [si], ah
	dec si
	xor ah, ah
	loop ($ - 18) ;div ebx
	call GetAll
}


macro printLen strs, col, x, y, len ;не очень таки и работает
{
	pusha
	push 0xB800
	mov ax, strs
	mov cx, len
	pop es
	mov si, ax ;в si указатель на символ
	xor di, di ;адрес es:di в В800:0000
	mov di, 2 * (x + y * 80)
	mov ah, col
	mov al, [si]
	cmp cx, 0 ;последний ли символ? ;start zd
	jz ($ + 10) ;end
	mov [es:di], ax
	inc si
	inc di
	inc di
	dec cx
	jmp ($ - 14) ;start
	popa ;end zd
}

macro printReg strs, col
{
	pusha
	push 0xB800
	pop es
	mov ax, strs
	mov si, ax ;в si указатель на символ
	xor di, di ;адрес es:di в В800:0000
	xor al, al
	mov al, dh ; y
	mov bl, 80
	mul bl ; * 80
	xor dh, dh
	add ax, dx ; + x
	add ax, ax ; * 2
	mov di, ax
	mov ah, col
	mov al, [si]
	cmp al, 0 ;последний ли символ?
	jz ($ + 9)
	mov [es:di], ax
	inc si
	inc di
	inc di
	jmp ($ - 12)
	popa
}

			macro print strs, col, x, y
			{
				pusha
				push 0xB800
				pop es
				mov ax, strs
				mov si, ax ;в si указатель на символ
				xor di, di ;адрес es:di в В800:0000
				mov di, 2 * (x + y * 80)
				mov ah, col
				mov al, [si]
				cmp al, 0 ;последний ли символ?
				jz ($ + 9)
				mov [es:di], ax
				inc si
				inc di
				inc di
				jmp ($ - 12)
				popa
			}

macro printDEB strs, col, x, y
{
	call SendAll
	push ds
	push 0xB800
	pop es
	xor ax, ax
	mov ds, ax
	mov ax, strs
	mov si, ax ;в si указатель на символ
	xor di, di ;адрес es:di в В800:0000
	mov di, 2 * (x + y * 80)
	mov ah, col
	mov al, [si]
	cmp al, 0 ;последний ли символ?
	jz ($ + 9)
	mov [es:di], ax
	inc si
	inc di
	inc di
	jmp ($ - 12)
	pop ds
	call GetAll
}

macro input x, y
{
	pusha
;buffer clear
	mov si, buff
	mov cx, 128
	xor al, al
;clearing
	mov [si], al ;to zero
	inc si
	loop ($ - 3) ;do 128 times
	sub si, 128
;cursor
	mov bl, 0
	mov dh, y
	mov dl, x
	mov ah, 02h
	int 10h
	push dx
	mov si, buff
;writing
	mov ah, 0 ;считать клавишу с клавиатуры
	int 16h
	cmp al, 0dh ;ne enter li eto?
	je ($ + 154) ;stop_input
	cmp al, 08h ;не backspace li eto?
	jne ($ + 29) ;нет

	pushf
	cmp cl, 0 ;стоит ли курсор в начале (можно ли стирать)
	je ($ + 61) ;gog
	
	cmp dl, 0 ;у границы экрана?
	jne ($ + 6) ;d

	mov dl, 80 
	dec dh ;на строку выше
;d
	dec dl ;на букву меньше

	xor al, al
	mov ah, 02h ;двигаем курсор
	int 10h

	dec cl ;less symbols
	dec si
	popf 

;nbkspce
	pushf
	cmp cl, 128
	je ($ + 32) ;gog
	
	push cx
	mov cx, 1
	mov ah, 0ah ;записать символ в позиции курсора
	int 10h
	pop cx
	mov [si], al
	popf
	je ($ + 18) ;gog
	inc si
	inc cl
	inc dl ;двигаемся по х
	cmp dl, 80 ;достигло ли края экрана
	jb ($ + 6) ;go
	xor dl, dl ;обнуляем
	inc dh ;двигаемся по у
;go
	mov ah, 02h ;двигаем курсор
	int 10h
;gog
	bcd cx, symbol
	print symbol, 1Eh, 49, 0
	jmp ($ - 157)

;stop_input
	inc dh
	xor dl, dl
	mov ah, 02h ;двигаем курсор
	int 10h
	popa
}

macro printe str, col, x, y
{
	pusha
	push col
	mov dl, y
	mov dh, x
	push dx
	push str
	call printFunc
	popa
}

macro inpute x, y
{
	pusha
	mov dl, y
	mov dh, x
	push dx
	call inputFunc
	popa
}

org 0500h

jmp _start

inputFunc: ;push X-Y
	pop cx
	pop dx
	xchg dh, dl
	push cx
;buffer clear
	mov si, buff
	mov cx, 128
	xor al, al
;clearing
	mov [si], al ;to zero
	inc si
	loop ($ - 3) ;do 128 times
	sub si, 128
;cursor
	mov bl, 0
	mov ah, 02h
	int 10h
	mov si, buff
_inpute_writing:
	mov ah, 0 ;считать клавишу с клавиатуры
	int 16h
	cmp al, 0dh ;ne enter li eto?
	je _inpute_stop_input
	cmp al, 08h ;не backspace li eto?
	jne _inpute_nbkspce ;нет
	pushf
	cmp cl, 0 ;стоит ли курсор в начале (можно ли стирать)
	jne _inpute_f
	popf
	jmp _inpute_writing
_inpute_f:
	cmp dl, 0 ;у границы экрана?
	jne _inpute_d
	mov dl, 80 
	dec dh ;на строку выше
_inpute_d:
	dec dl ;на букву меньше
	xor al, al
	mov ah, 02h ;двигаем курсор
	int 10h
	dec cl ;less symbols
	dec si
	popf 
_inpute_nbkspce:
	pushf
	cmp cl, 128
	jne _inpute_e
	popf
	jmp _inpute_writing
_inpute_e:
	push cx ;f
	mov cx, 1
	mov ah, 0ah ;записать символ в позиции курсора
	int 10h
	pop cx ;f
	cmp dx, 0x184F	
	jl _inpute_a
	call MOVE_SCRN_UP
	dec dh
_inpute_a:
	mov [si], al
	popf
	je _inpute_gog
	inc si
	inc cl
	inc dl ;двигаемся по х
	cmp dl, 80 ;достигло ли края экрана
	jb _inpute_go
	xor dl, dl ;обнуляем
	inc dh ;двигаемся по у
_inpute_go:
	mov ah, 02h ;двигаем курсор
	int 10h
_inpute_gog:
	bcd cx, symbol
	print symbol, 1Eh, 49, 0
	jmp _inpute_writing
_inpute_stop_input:
	cmp dh, 24
	jl _inpute_b
	call MOVE_SCRN_UP
	jmp _inpute_c
_inpute_b:
	inc dh
_inpute_c:
	xor dl, dl
	mov ah, 02h ;двигаем курсор
	int 10h
	
	RET

printFunc: ;push COL (ah), push X-Y, push STR
	pop cx
	pop si ;STR
	pop ax  ;X-Y

	pusha
	mov dl, ah
	mov dh, al
	xor bh, bh
	mov ah, 2
	int 10h
	popa

	mov bh, 80
	xchg ah, bl
	mul bh ;y * 80
	xor bh, bh
	add ax, bx ;x + y * 80
	shl ax, 1 ; x2
	mov di, ax ;2 * (x + y * 80)
	pop ax   ;COL
	shl ax, 8
	push 0xB800
	pop es
	push cx
	
_printe_next:
	cmp di, 2 * WIDTH_T * HEIGHT_T
	jl _printe_a
	call MOVE_SCRN_UP
	sub di, 2 * WIDTH_T
	pop cx
	call SendAll
	popa
	dec dh
	pusha
	call GetAll
	push cx
	jmp _printe_next
_printe_a:
	mov al, [si]
	cmp al, 0x0D ;энтер ли это?
	jne _printe_not_enter ;нет
	cmp di, 2 * (WIDTH_T * (HEIGHT_T - 1)) ;находится дальше чем в конце предпоследней строки?
	jle _printe_NoNeedToScroll ;no
	call MOVE_SCRN_UP
	mov di, 2 * WIDTH_T * (HEIGHT_T - 1)
	inc si
	jmp _printe_next ;
_printe_NoNeedToScroll:
	push ax
	push bx
	mov ax, di
	mov bl, WIDTH_T * 2
	div bl
	mul bl
	mov di, ax
	add di, WIDTH_T * 2
	inc si
	pop bx
	pop ax
	jmp _printe_next ;
_printe_not_enter:
	cmp al, 0 ;последний ли символ?
	jz _printe_end
	mov [es:di], ax
	inc si
	inc di
	inc di
	jmp _printe_next
_printe_end:
	
	ret

MOVE_SCRN_UP:
	pusha
	mov cx, 0x0100 ; 1, 0, левый верх
	mov dx, 0x184F ;25 - 1, 80 - 1, правый низ
	mov al, 1
	mov bh, 0x07
	mov ah, 06h
	int 0x10
	popa
	RET

_start: ;             BEGINNING!!!


;mov eax, $ + 9
;call debug

push 050h
pop es



;ramonter
printe strR, 01Fh, 4, 0

	

mov bh, 0 ;видеостраница
mov cx, 1 ;кол-во символов



printe str_SYMBS, 1Ch, 40, 0


mov dh, 1
jmp next_cmd

_HW:
printe str_HW, 07h, 0, dh
jmp next_cmd

_ERS:
jmp next_cmd



cmding:

xor cx, cx
bcd cx, symbol

printe symbol, 1Eh, 49, 0

getToSizeOfScrn:
cmp dh, HEIGHT_T
jl getToSizeOfScrn_e
dec dh
jmp getToSizeOfScrn
getToSizeOfScrn_e:

inpute 15, dh


mov ah, 03h
xor bh, bh
int 10h

mov si, buff
mov di, CMD_LIST
xor ax, ax
mov bx, 8

cmpare: ;ищем нужную команду
	mov cx, [di]
	cmp [si], cx ;сравниваем букву
	je LET ;если совпадает
	sub cx, 20h
	cmp [si], cx ;сравниваем букву
	je LET ;если совпадает
TO_NEXT_ZERO: ;если нет, бежим к следующему нулю
	inc di
	cmp [di], bl ;не нашлась команда?
	je unkn
	cmp [di], bh ;ноль?
	jne ($ + 3) ;нет
	inc ax ;да
	jne TO_NEXT_ZERO
LET:
	inc di
	inc si
	cmp [di], bl
	je end_of_cmparing
	cmp [di], bh
	jne cmpare
end_of_cmparing:
cmp ax, 0
je _FORMAT
cmp ax, 1
je _SD
cmp ax, 2
je _HW
cmp ax, 3
je _ERS
cmp ax, 4
je _TIME



unkn:


printe str_BDCMD, 07h, 0, dh
inc dh
inc dh

next_cmd:
printe str_ENTRCMD, 07h, 0, dh
;printReg str_ENTRCMD, 07h

jmp cmding

strR db 'Ramonter v0.03', END_STR

;strF db 'Do you want to format disk? (y/n)', END_STR

times 11 db 0

str_SYMBS db 'SYMBOLS: ', END_STR

str_ENTRCMD db 'Enter command:', END_STR

str_BDCMD db 'Unknown command!', ENDL, 'Try again!!!', END_STR

str_HW db 'Hello', ENDL, 'World!', ENDL, 'this', ENDL, 'is', ENDL, 'MEEE!!!!!!!!!!!!!!!!!!!!!!', END_STR

CMD_LIST db 'format', 0, 'sd', 0, 'hw', 0, 'ers', 0, 'time', 8

_SD:
mov ax,5301h ;activate real-mode APM interface
xor bx,bx
int 15h

mov ax,530eh ;Select APM version
xor bx,bx
mov cx,0102h ;v1.2
int 15h

mov ax,530fh ;Activate APM for every devices
mov bx,0001h ;ID 1=everyl devices
mov cx,0001h ;1=engage
int 15h

mov ax,5308h ;Atomatically activate APM for every devices
mov bx,0001h ;ID 1=every device
mov cx,0001h ;1=enable
int 15h

mov ax,5307h ;set device state
mov bx,0001h ;ID 1=every device
mov cx,0003h ;status 3=Shutdown
int 15h
ret

_TIME:
jmp next_cmd

_FORMAT:
jmp next_cmd
	




jmp $


		
jmp $	

SendAll:
	mov [TEAX], eax
	mov [TEBX], ebx
	mov [TECX], ecx
	mov [TEDX], edx
	mov [TESI], esi
	mov [TEDI], edi
	mov [TDS], ds
	ret

GetAll:
	mov eax, [TEAX]
	mov ebx, [TEBX]
	mov ecx, [TECX]
	mov edx, [TEDX]
	mov esi, [TESI]
	mov edi, [TEDI]
	mov ds, [TDS]
	ret

WaitForKey:
 	pusha
	mov ah, 0
	int 16h
	popa
	ret
	



com_hex db 0
times 12 db 0
		
		
		
	
	
	

;var_x db 0
;var_y db 0



TEAX dd 0
TEBX dd 0
TECX dd 0
TEDX dd 0
TESI dd 0
TEDI dd 0
TDS dw 0

str_EAXt db 'EAX:', 0
str_EBXt db 'EBX:', 0
str_ECXt db 'ECX:', 0
str_EDXt db 'EDX:', 0
str_ESIt db 'ESI:', 0
str_DSt db 'DS: ', 0
str_EAX db '00000000', 0
str_EBX db '00000000', 0
str_ECX db '00000000', 0
str_EDX db '00000000', 0
str_ESI db '00000000', 0
str_DS db '0000    ', 0
str_0x db '0x', 0
str_ENTtoPRCD db 'Enter to proceed', 0
str_CQtoQUIT db 'CTRL+Q to quit', 0

;bm_DEBUGWINBUFF db 0
;times 413 db 0

bm_RAM db	5, 5, 1, 2, 5, 5, 5, 5, 0
db		5, 5, 1, 2, 5, 5, 5, 5, 0
db		1, 1, 1, 2, 2, 2, 2, 2, 0
db		1, 5, 5, 5, 5, 5, 5, 2, 0
db		1, 5, 5, 5, 5, 5, 5, 2, 0
db		1, 1, 1, 2, 2, 2, 2, 2, 0
db		5, 5, 1, 2, 5, 5, 5, 5, 0
db		5, 5, 1, 2, 5, 5, 5, 5, 4



;CMD_TABLE db	007h, 1
;db		060h, 1, 068h, 3, 06Ah, 2
;db		0B8h, 3
;db		0


buff db 0 ;буфер
times 131 db 0

symbol db 0
times 3 db 0




;times 327680 - ($-500h + 512) db 0

;cyl=40
 ; heads=2
 ; sectors per track=8
 ; total sectors=640
 ; total bytes=327680
