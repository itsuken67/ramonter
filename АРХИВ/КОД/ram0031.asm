HEIGHT_T = 25
WIDTH_T = 80
ENDL = 0x0D
APOSTROPH = 0x27
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
mov ch, 0 ;10bit - cyl, 6bit - sector
mov cl, 2 ;sector
mov al, 7
xor bx, bx

mov ah, 02h
int 13h

mov dl, 0
mov dh, 1
mov bx, 0x0E00
mov ch, 0
mov cl, 1
mov al, 8

mov ah, 02h
int 13h


jmp 0080:0000
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
	mov al, y
	mov ah, x
	push ax
	push str
	call printFunc
	popa
}

macro printo str
{
	printe str, 07h, dl, dh
	mov edx, [TEDX]
}

macro inpute x, y, len
{
	pusha
	xor ah, ah
	mov al, len
	push ax
	mov al, y
	mov ah, x
	push ax
	call inputFunc
	popa
}

macro inputo len
{
	inpute dl, dh, len
	mov ah, 03h
	xor bh, bh
	int 10h
}

macro printeSymb sym, col, x, y, len
{
	pusha
	mov al, y
	mov ah, x
	push ax
	push len
	mov al, sym
	mov ah, col
	push ax
	call printSymb
	popa
}

macro printoSymb sym, len
{
	printeSymb sym, 07h, dl, dh, len
	mov edx, [TEDX]
	xor bh, bh
	mov ah, 2
	int 0x10
}

macro bcdToAscii value, rcv
{
	pusha
	xor ah, ah
	mov al, value
	push ax
	push rcv
	call BCD_TO_ASCII
	popa
}

macro ByteToASCII value, rcv
{
	pusha
	xor ah, ah
	mov al, value
	push ax
	push rcv
	call _ByteToASCII
	popa
}

macro ExtToASCII value, rcv
{
	pusha
	push value
	push rcv
	call _ExtToASCII
	popa
}

org 0500h

jmp _start

inputFunc: ;push len, push X-Y
	pop cx
	pop dx
	xchg dh, dl
	pop bx
	mov [TEBX], ebx
	push cx
	call cleanBuff
;cursor
	xor bx, bx
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
	mov ebx, [TEBX]
	cmp cl, bl ; 128
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
	ByteToASCII cl, symbol
	print symbol, 1Eh, 76, 0
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

getCursorPos:
	push ax
	push bx
	xor bh, bh
	mov ah, 3
	int 10h
	pop bx
	pop ax
	RET

printSymb: ;push X-Y, push LEN, push SYM (al)
	pop dx
	pop bx ;sym
	pop cx ;len
	pop ax ;x-y
	push dx
	push 0xB800
	pop es
	push bx
	mov bh, 80
	xchg ah, bl
	mul bh ;y * 80
	xor bh, bh
	add ax, bx ;x + y * 80
	shl ax, 1 ; x2
	mov di, ax ;2 * (x + y * 80)
	pop bx
_printSymb_a:
	mov [es:di], bx
	inc di
	inc di
	loop _printSymb_a
	mov ax, di
	shr ax, 1 ;/ 2
	;add ax, 1
	mov bh, 80
	div bh
	mov dl, ah
	mov dh, al
	xor bh, bh
	mov ah, 2
	int 0x10
	mov [TEDX], edx
	RET
	

printFunc: ;push COL (ah), push X-Y, push STR
	pop cx
	pop si ;STR
	pop ax  ;X-Y

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
	mov ax, di
	shr ax, 1 ;/ 2
	;add ax, 1
	mov bh, 80
	div bh
	mov dl, ah
	mov dh, al
	mov [TEDX], edx
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

cleanBuff:
	mov si, buff
	mov cx, 128
	xor al, al
	mov [si], al ;to zero
	inc si
	loop ($ - 3) ;do 128 times
	sub si, 128
	ret

cleanFormatBuff:
	mov si, _FORMAT_BUFF
	mov cx, 128
	xor eax, eax
cleanFormatBuff_DO:
	mov [si], eax ;to zero
	add si, 4
	loop cleanFormatBuff_DO ;do 128 times
	ret

CMPE_WITH_BUFF:
	pop cx
	pop di
	push cx
	mov cx, 128
	
	RET

MoveToNearestSpace:
	push dx
	mov dl, ' '
_MoveToNearestSpace_checkForSpace:
	cmp [si], dl
	jne MoveToNearestSpace_w
	inc si
	cmp si, buff + 128
	je _PRC_BAD_MVTOs
	jmp _MoveToNearestSpace_checkForSpace
MoveToNearestSpace_w:
	pop dx
	RET

_PRC_BAD_MVTOs:
	pop dx
	printo _PRC_BAD_MVTO
	jmp next_cmd

cleanCOMMON:
	push eax
	push si
	push cx
	mov si, _COMMON
	mov cx, 4
	xor eax, eax
_cleanCOMMON_DO:
	mov [si], eax
	add si, 4
	loop _cleanCOMMON_DO
	pop cx
	pop si
	pop eax
	RET
	

_start: ;             BEGINNING!!!

;mov eax, $ + 9
;call debug

push 050h
pop es

;ramonter
printeSymb 0, 1Fh, 0, 0, 80
printe strR, 04Fh, 0, 0


mov bh, 0 ;видеостраница
mov cx, 1 ;кол-во символов

printe str_SYMBS, 1Fh, 67, 0

xor dx, dx
jmp next_cmd

_BYTE_TO_HEX_ASCII: 
	pop cx
	pop si
	pop ax
	push cx
	inc si
	mov cx, 2
	mov bl, 16
_BYTE_TO_HEX_ASCII_DO:
	div bl
	cmp ah, 10
	jl _BYTE_TO_HEX_ASCII_LETTER_NOT
	add ah, 07h ;БУКВЫ
_BYTE_TO_HEX_ASCII_LETTER_NOT:
	add ah, 30h
	mov [si], ah
	dec si
	xor ah, ah
	loop _BYTE_TO_HEX_ASCII_DO ;div ebx
	RET

str_0x db '0x', 0

macro BYTE_TO_HEX_ASCII byte, rcv
{
	pusha
	mov al, byte
	xor ah, ah
	push ax
	push rcv
	call _BYTE_TO_HEX_ASCII
	popa
}

_FORMAT_MAX_HEAD db 0
_FORMAT_MAX_CYL db 0
_FORMAT_MAX_SEC db 0

_FORMAT:
	jmp _FORMAT_QUE
_FORMAT_BAD_ANS:
	printo _YN_BAD
_FORMAT_QUE:
	printo _FORMAT_Q
	inputo 1
	cmp [buff], 'n'
	je _FORMAT_NOT
	cmp [buff], 'N'
	je _FORMAT_NOT
	cmp [buff], 'y'
	je _FORMAT_DO
	cmp [buff], 'Y'
	je _FORMAT_DO
	jmp _FORMAT_BAD_ANS
_FORMAT_NOT:
	printo _CANCEL
	jmp next_cmd
_FORMAT_DO:
	call cleanFormatBuff
	push dx
	mov dl, 80h
	mov ah, 8
	int 13h
	mov [_FORMAT_MAX_CYL], ch
	mov [_FORMAT_MAX_HEAD], dh
	mov [_FORMAT_MAX_SEC], cl
	mov ch, 0
	mov cl, 1
	mov dh, 0
	mov dl, 80h
	push 0x0050
	pop es
	mov bx, _FORMAT_BUFF - 500h
_FORMAT_START:
	mov ah, 3
	mov al, 1
	int 13h
	jb _FORMAT_ERROR
	cmp cl, [_FORMAT_MAX_SEC]
	jne _FORMAT_NEXT_SEC
	cmp dh, [_FORMAT_MAX_HEAD]
	jne _FORMAT_NEXT_HEAD
	cmp ch, [_FORMAT_MAX_CYL]
	jne _FORMAT_START
_FORMAT_END:
	pop dx
	printo _DONE
	jmp next_cmd

_FORMAT_NEXT_SEC:
	inc cl
	jmp _FORMAT_START

_FORMAT_NEXT_HEAD:
	inc dh
	mov cl, 1
	jmp _FORMAT_START

_FORMAT_NEXT_CYL:
	inc ch
	xor dh, dh
	jmp _FORMAT_START

_FORMAT_ERROR:
	pop dx
	call cleanCOMMON
	BYTE_TO_HEX_ASCII ah, _COMMON
	printo _ERROR
	printo _ERROR_CODE
	printo str_0x
	printo _COMMON
	jmp next_cmd
	
	
	

_OFF:
	printo str_OFF
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



str_HW db 'Hello', ENDL, 'World!', ENDL, 'this', ENDL, 'is', ENDL, 'MEEE!!!!!!!!!!!!!!!!!!!!!!', END_STR

_HW:
	printo str_HW
	jmp next_cmd



_ERS:
	mov ax, 3
	int 10h
	printeSymb 0, 1Fh, 0, 0, 80
	printe strR, 04Fh, 0, 0
	printe str_SYMBS, 1Fh, 67, 0
	xor dx, dx
	jmp next_cmd



BCD_TO_ASCII: ;push value (al), push rcv
	pop dx
	pop di
	pop ax
	xor ah, ah
	shl ax, 4
	shr al, 4
	add ax, 0x3030
	mov [di], ah
	inc di
	mov [di], al
	push dx
	ret

str_MON db 0
times 3 db 0
str_MONTH_LIST db 'JAN', 0, 'FEB', 0, 'MAR', 0, 'APR', 0, 'MAY', 0, 'JUN', 0, 'JUL', 0, 'AUG', 0, 'SEP', 0, 'OCT', 0, 'NOV', 0, 'DEC', 0
_TIME_HRS db 0
_TIME_MIN db 0
_TIME_SEC db 0
_TIME_HRS_BCD db '00', ':'
_TIME_MIN_BCD db '00', ':'
_TIME_SEC_BCD db '00', END_STR
_TIME_DAY_BCD db '00', END_STR
_TIME_YYR_BCD db '0000', END_STR

_TIME:
	push dx
	mov ah, 2
	int 0x1a ;CH:CL:DH - HH:MM:SS
	bcdToAscii ch, _TIME_HRS_BCD
	bcdToAscii cl, _TIME_MIN_BCD
	bcdToAscii dh, _TIME_SEC_BCD
	mov ah, 4
	int 0x1a ;DH.DL.CHCL - MM.DD.YYYY
	bcdToAscii dl, _TIME_DAY_BCD
	bcdToAscii ch, _TIME_YYR_BCD
	bcdToAscii cl, _TIME_YYR_BCD + 2
	mov bl, dh
	xor bh, bh
	shl bx, 4
	shr bl, 4
	cmp bh, 1
	jne _TIME_B
	add bl, 10
_TIME_B:
	dec bl
	xor bh, bh
	shl bx, 2
	mov si, str_MONTH_LIST
	add si, bx

	pop dx
	printo _TIME_HRS_BCD
	printoSymb ' ', 3
	printo _TIME_DAY_BCD
	printoSymb ' ', 1
	printo si
	printoSymb ' ', 1
	printo _TIME_YYR_BCD
	jmp next_cmd



_ByteToASCII: ;push value (al), push rcv
	pop cx
	mov [TECX], ecx
	pop si
	pop ax
	inc si
	inc si
	mov bl, 10
	mov cx, 3
_NumToASCII_div:
	div bl
	push ax
	add ah, 30h
	mov [si], ah
	pop ax
	dec si
	xor ah, ah
	loop _NumToASCII_div
;remove_nulls
	inc si
	mov ah, '0'
	mov al, ' '
	mov cx, 2
_NumToASCII_a:
	cmp [si], ah
	jne _NumToASCII_end
	mov bl, [si + 1]
	mov [si], bl
	mov bl, [si + 2]
	mov [si + 1], bl
	mov [si + 2], al
	loop _NumToASCII_a
_NumToASCII_end:
	mov ecx, [TECX]
	push cx
	RET

_ExtToASCII: ;push value (eax), push rcv
	pop cx
	mov [TECX], ecx
	pop si
	pop eax
	add si, 9
	mov ebx, 10
	mov cx, bx
	xor edx, edx
_ExtToASCII_div:
	div ebx
	push dx
	add dl, 30h
	mov [si], dl
	pop dx
	dec si
	xor dx, dx
	loop _ExtToASCII_div
;remove_nulls
	mov ah, '0'
	inc si
	xor al, al
	mov cx, 9
_ExtToASCII_a:
	cmp [si], ah
	jne _ExtToASCII_end
	mov dl, 9
_ExtToASCII_f:
	mov bl, [si + 1]
	mov [si], bl
	inc si
	dec dl
	cmp dl, 0
	jne _ExtToASCII_f
	sub si, 9
	mov [si + 9], al
	loop _ExtToASCII_a
_ExtToASCII_end:
	mov ecx, [TECX]
	push cx
	RET

_DISKINFO:
	push dx
	mov ah, 8 ;получить данные о диске
	mov dl, 80h
	int 13h 
	inc dh
	call cleanCOMMON
	ByteToASCII dh, _COMMON
	mov bl, dh
	pop dx
	printo _DISKINFO_H
	printo _COMMON
	printo str_ENDL
	inc ch
	call cleanCOMMON
	ByteToASCII ch, _COMMON
	printo _DISKINFO_C
	printo _COMMON
	printo str_ENDL
	call cleanCOMMON
	ByteToASCII cl, _COMMON
	printo _DISKINFO_S
	printo _COMMON
	printo str_ENDL
	push dx
	mov dh, bl
	xor eax, eax
	xor ebx, ebx
	mov al, dh
	mov bl, ch
	mul ebx
	mov bl, cl
	mul ebx
	shl edx, 16
	mov dx, ax
	shr edx, 1
	call cleanCOMMON
	ExtToASCII edx, _COMMON
	pop dx
	printo _COMMON
	printo _DISKINFO_KB
	jmp next_cmd



_DISK_EmptyDisk db 'Your disk has not a single file!', END_STR

_DISK:
	printo _DISK_EmptyDisk
	jmp next_cmd



_RAM:
	xor cl, cl
_RAM_cmp:
	cmp cl, 0
	je _RAM_0
	cmp cl, 6
	je _RAM_0
	cmp cl, 2
	je _RAM_1
	cmp cl, 5
	je _RAM_1
	cmp cl, 3
	je _RAM_1
	jmp next_cmd
_RAM_0:
	mov di, bm_RAM_0
	mov ch, 2
	jmp _RAM_b
_RAM_1:
	mov di, bm_RAM_1
	mov ch, 1
	jmp _RAM_b
_RAM_2:
	mov di, bm_RAM_2
	mov ch, 2
	jmp _RAM_b
_RAM_b:
	mov si, di
_RAM_a:
	mov ah, [si]
	cmp ah, 0x55
	je _RAM_xd
	xor bh, bh
	mov bl, [si+1]
	printeSymb 0xDB, ah, dl, dh, bx
	mov edx, [TEDX]
	inc si
	inc si
	jmp _RAM_a
_RAM_xd:
	printo str_ENDL
	dec ch
	inc cl
	cmp ch, 0
	jne _RAM_b
	jmp _RAM_cmp


	
_PRC:
	push dx
	mov si, buff
	call MoveToNearestSpace
	add si, 4
	call MoveToNearestSpace
	xor eax, eax
	mov ebx, 10
	mov ch, '9'
	mov cl, '0' 
	xor dl, dl
	mov dh, ' '
_PRC_GETNUM:
	cmp [si], cl ;правильно ли написано число?
	jl _PRC_BAD
	cmp ch, [si] ;правильно ли написано число? х2
	jb _PRC_BAD
	mul ebx ;умножаем на 10
	xor edx, edx
	mov dl, [si]
	sub dl, 30h
	add eax, edx ;и прибавляем цифру
	jb _PRC_BIG
	inc si
	xor dl, dl
	mov dh, ' '
	cmp [si], dl ;дошли до конца?
	je _PRC_DO
	cmp [si], dh ;дошли до конца? х2
	je _PRC_DO
	jmp _PRC_GETNUM
_PRC_DO:
	mov ebx, eax ;кол-во раз требуется - ebx
	xor eax, eax
	mov ecx, eax ;кол-во раз сделано - ecx
	pop dx
_PRC_START:
	push dx
	mov edx, 100
	inc ecx
	mov eax, ecx
	mul edx
	div ebx
	push ecx
	mov ecx, ebx
	shr ecx, 1
	jnb _PRC_Z
	inc ecx
_PRC_Z:
	cmp edx, ecx
	jl _PRC_A
	inc eax
_PRC_A:
	call cleanCOMMON
	pop ecx
	pop dx
	ByteToASCII al, _COMMON
	printo _COMMON
	printoSymb '%', 1
	printo str_ENDL
	pusha
	xor ah, ah
	int 16h
	popa
	cmp ecx, ebx
	jne _PRC_START
	jmp next_cmd
	

_PRC_BIG:	
	pop dx
	printo str_PRC_BIG
	jmp next_cmd

_PRC_BAD:	
	pop dx
	printo _BAD_SYNTAX
	jmp next_cmd



cmding:

xor cx, cx
ByteToASCII cl, symbol

printe symbol, 1Eh, 76, 0

getToSizeOfScrn:
cmp dh, HEIGHT_T
jl getToSizeOfScrn_e
dec dh
jmp getToSizeOfScrn
getToSizeOfScrn_e:

inputo 128


mov si, buff
mov di, CMD_LIST
xor ax, ax
mov bx, 8

push dx
mov dl, ' '
mov cx, 127
_cmpare_checkForSpace:
	cmp [si], dl
	jne cmpare_w
	inc si
	loop _cmpare_checkForSpace
cmpare_w:
	mov dx, si
	shl esi, 16
	mov si, dx
	pop dx
	


cmpare: ;ищем нужную команду
	mov cl, [di]
	cmp [si], cl ;сравниваем букву
	je LET ;если совпадает
	add cl, 20h
	cmp [si], cl ;сравниваем букву
	je LET ;если совпадает
TO_NEXT_ZERO: ;если нет, бежим к следующему нулю
	inc di
	cmp [di], bl ;не нашлась команда?
	je unkn
	cmp [di], bh ;ноль?
	jne _cmpare_a ;нет
	pushf
	inc ax ;да
	shr esi, 16
	push si
	shl esi, 16
	pop si
	inc di
	popf
_cmpare_a:
	jne TO_NEXT_ZERO
	jmp cmpare
LET:
	inc di
	inc si
	cmp [di], bl
	je end_of_cmparing
	cmp [di], bh
	jne cmpare
end_of_cmparing:
mov bx, JUMPING
add bx, ax
add ax, ax
add bx, ax ;JUMPING + ax * 3
mov ax, cs
shl ax, 4 ;двигаем CS на одну тетраду вперёд (0х0050 -> 0x0500)
sub bx, ax
jmp bx
JUMPING:
jmp _FORMAT
jmp _OFF
jmp _HW
jmp _ERS
jmp _TIME
jmp _DISKINFO
jmp _DISK
jmp _RAM
jmp _PRC

unkn:
printo str_BDCMD

next_cmd:
printo str_ENTRCMD
jmp cmding

strR db 'Ramonter v0.031', END_STR

_YN_BAD db 'Type Y for YES and N for NO', ENDL, END_STR
_CANCEL db 'Cancelling...', END_STR

_DONE db 'Done!', END_STR

_ERROR db 'Something went wrong...', ENDL, END_STR
_ERROR_CODE db 'Error Code: ', END_STR
_BAD_SYNTAX db 'Syntax Error', END_STR
_PRC_BAD_MVTO db 'Was bad at getting num', ENDL
str_PRC_BIG db 'Your number is way too big!', END_STR

_FORMAT_Q db 'Do you want to FORMAT disk?', ENDL, 'THIS PROCEDURE IS GOING TO ERASE ALL EXISTING DATA ON IT: (y/n): ', END_STR
_FORMAT_CODE00 db 'Success', END_STR
_FORMAT_CODE01 db 'Bad command', END_STR
_FORMAT_CODE02 db 'Bad address mark', END_STR
_FORMAT_CODE03 db 'Attempt to rewrite a white protected disk', END_STR
_FORMAT_CODE04 db 'Sector ID is ruined or not found', END_STR
_FORMAT_CODE05 db 'Reset failure', END_STR
_FORMAT_CODE06 db 'Disk change line ', APOSTROPH, 'active', APOSTROPH, END_STR
_FORMAT_CODE07 db 'Drive parameter activity failed', END_STR
_FORMAT_CODE08 db 'DMA failure', END_STR
_FORMAT_CODE09 db 'Attempt to DMA over 64KB boundary', END_STR
_FORMAT_CODE0A db 'Got to a bad sector', END_STR
_FORMAT_CODE0B db 'Got to a bad track/cylinder', END_STR
_FORMAT_CODE0C db 'Media type not found', END_STR
_FORMAT_CODE0D db 'Bad number of sectors', END_STR
_FORMAT_CODE0E db 'Control data address mark detected', END_STR
_FORMAT_CODE0F db 'DMA out of range', END_STR
_FORMAT_CODE10 db 'CRC/ECC failure', END_STR
_FORMAT_CODE11 db 'ECC corrected data error', END_STR
_FORMAT_CODE20 db 'Controller failure', END_STR
_FORMAT_CODE40 db 'Could', APOSTROPH, 't find track', END_STR
_FORMAT_CODE80 db 'Time out', END_STR
_FORMAT_CODEAA db 'Disk not ready', END_STR
_FORMAT_CODEBB db 'Unknown error', END_STR
_FORMAT_CODECC db 'Write fault', END_STR
_FORMAT_CODEE0 db 'Status error', END_STR
_FORMAT_CODEFF db 'Sense operation failed', END_STR

times 11 db 0

str_SYMBS db 'SYMBOLS:', END_STR

str_ENTRCMD db ENDL, 'Enter command: ', END_STR
str_ENDL db ENDL, END_STR

str_OFF db 'Shutdown!', END_STR

str_BDCMD db 'Unknown command!', END_STR

_COMMON db 0
times 16 db 0

_DISKINFO_H db 'Heads: ', END_STR
_DISKINFO_C db 'Cylinders: ', END_STR
_DISKINFO_S db 'Sectors: ', END_STR
_DISKINFO_KB db ' kilobytes', END_STR



str_GW db 'change da world.', ENDL, 'my final message.', ENDL, 'goodbye.', END_STR

CMD_LIST db 	'FORMAT', 0
db		'OFF', 0 
db		'HW', 0
db		'ERS', 0
db		'TIME', 0
db 		'DISKINFO', 0
db		'DISK', 0
db 		'RAMONTER!', 0
db		'PRC'
db		8

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
str_ENTtoPRCD db 'Enter to proceed', 0
str_CQtoQUIT db 'CTRL+Q to quit', 0

;bm_DEBUGWINBUFF db 0
;times 413 db 0

bm_RAM_0 db	0x00, 2, 0xdd, 1, 0x99, 1, 0x00, 4, 0x55
bm_RAM_1 db 	0x0d, 3, 0x99, 5, 0x55
bm_RAM_2 db	0x0d, 1, 0x00, 6, 0x09, 1, 0x55

;CMD_TABLE db	007h, 1
;db		060h, 1, 068h, 3, 06Ah, 2
;db		0B8h, 3
;db		0

buff_cmp db 0
times 127 db 0

buff db 0 ;буфер
times 131 db 0

symbol db 0
times 3 db 0

_FORMAT_BUFF db 0x86
times 510 db 0x86
db 0x0D

times 327680 - ($-500h + 512) db 0

;cyl=40
 ; heads=2
 ; sectors per track=8
 ; total sectors=640
 ; total bytes=327680
