HEIGHT_T = 25
WIDTH_T = 80

org 7c00h
;CODE

mov esi, wr
jmp $

wr db 0



times 510 - $ + 7c00h db 0
db 0x55, 0xAA

;je _FORMAT
;_FORMAT:
;copy_to_buff:
;		mov cx, 9
;		mov di, bm_DEBUGWINBUFF
;		push 2 * (15 * 80 + 52) ;окно начинается на х: 52, у: 15
;		pop si
;		push 0xB800
;		pop ds
;		push 0
;		pop es
;	copy_line:
;		xor dl, dl ;строка - 23 пикс, каждый пикс - 2 байта
;	copy_byte:
;		mov ax, [ds:si]
;		mov [di], ax
;		mov al, ' '
;		;mov [ds:si], al
;
;		pusha
;		mov ah, 0
;		int 16h
;		popa
;
;		inc si
;		inc di
;		mov ax, [ds:si] ;берём байт цвета
;		mov [di], ax ;и отправляем в буфер
;		cmp dl, 4
;		jb red_debigwin ;закрасить пикс красным
;		jle blue_debigwin ;закрасить пикс синим
;
;		pusha
;		mov ah, 0
;		int 16h
;		popa
;;
;		inc dl
;		inc si
;		inc di
;		cmp dl, 24 ;закончил ли строку?
;		jne copy_byte
;		add si, 160 - 46
;		loop copy_line
;		ret