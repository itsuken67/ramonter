HEIGHT_T = 25
WIDTH_T = 80
ENDL = 0x0D
END_STR = 0x00

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


macro printo str
{
	printe str, 07h, dl, dh
	mov edx, [TEDX]
}

macro ExtToASCII value, rcv
{
	pusha
	push value
	push rcv
	call _ExtToASCII
	popa
}

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
mov al, 4
xor bx, bx

mov ah, 02h
int 13h




jmp 0080:0000
jmp $

fd db 'error!'

times 510 - ($-7c00h) db 0
db 055h, 0AAh ;ДАЛЬШЕ ЗАГРУЗЧИК НЕ ИДЁТ

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

org 0500h

jmp _start

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
	inc si
	mov ah, '0'
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

_start:

push 0500h
pop es

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
	printo _PROC
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

unkn:
next_cmd:
printo _END
jmp $


_ERROR db 'Something went wrong...', END_STR
_ERROR_CODE db 'Error Code: ', END_STR
_BAD_SYNTAX db 'Syntax Error', END_STR
_PRC_BAD_MVTO db 'Was bad at getting num', ENDL
str_PRC_BIG db 'Your number is way too big!', END_STR
_END db ENDL, 'end.', 0

_PROC db '%', 0

str_ENDL db ENDL, 0

buff db 'prc 7'
times 128 db 0

_DISKINFO_KB db ' kilobytes', END_STR

_COMMON db 0
times 13 db 0

TEDX dd 0
TECX dd 0

;380C
;7422

;0C74
;9871
