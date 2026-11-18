org 7c00h

_MAX_ = 640 * 480
_MAX_WORDS_ = _MAX_ / 16
COL = 0Bh
GC_PORT = 3CEh
X = 1
Y = 1


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
mov al, 12h
int 10h

;pusha
;mov ax, 01312h
;mov bp, strR
;mov cx, lenstrR
;mov bl, 0Fh
;int 10h
;popa

mov ax, 0x0012 ;функция
int 10h




push 0xA000
pop es
mov dx, GC_PORT ;ПОРТ ГРАФ КОНТРОЛЛЕРА
mov ax, 0F01h ; 1 - РЕГИСТР РАЗРЕШЕНИЯ УСТАНОВКИ СБРОСА
out dx, ax ;ОПТРАВЛЯЕМ В ПОРТ ГРАФ КОНТРОЛЛЕРА
mov ah, COL ;ЦВЕТ
mov al, 0 ; 0 - РЕГИСТР УСТАНОВКИ СБРОСА
out dx, ax ;ОПТРАВЛЯЕМ В ПОРТ ГРАФ КОНТРОЛЛЕРА
mov al, 5 ; РЕГИСТР ГРАФ РЕЖИМА В ГК
out dx, al
inc dx ;DX = 3CFh
in al, dx
or al, 0Bh
out dx, al
dec dx; DX = 3CEh
mov ax, 7 ;РЕГИСТР БЕЗРАЗЛИЧИЯ ЦВЕТА
out dx, ax
mov ax, 0FF08h ;8 - РЕГИСТР БИТОВОЙ МАСКИ
out dx, ax
mov di, 0 ;Y*80+X/8
mov ax, 0FFFFh
mov cx, _MAX_WORDS_
rep stosw

mov dx, GC_PORT ;ПОРТ ГРАФ КОНТРОЛЛЕРА
mov ax, 0F01h ; 1 - РЕГИСТР РАЗРЕШЕНИЯ УСТАНОВКИ СБРОСА
out dx, ax ;ОПТРАВЛЯЕМ В ПОРТ ГРАФ КОНТРОЛЛЕРА
mov ah, 0Dh ;ЦВЕТ
mov al, 0 ; 0 - РЕГИСТР УСТАНОВКИ СБРОСА
out dx, ax ;ОПТРАВЛЯЕМ В ПОРТ ГРАФ КОНТРОЛЛЕРА
;mov al, 5 ; РЕГИСТР ГРАФ РЕЖИМА В ГК
;out dx, al
;inc dx ;DX = 3CFh
;in al, dx
;or al, 0Bh
;out dx, al
;dec dx; DX = 3CEh
;mov ax, 7 ;РЕГИСТР БЕЗРАЗЛИЧИЯ ЦВЕТА
;out dx, ax
mov ax, 0FF08h ;8 - РЕГИСТР БИТОВОЙ МАСКИ
out dx, ax
mov di, 0 ;
mov ax, 0FEFFh
stosw



;mov ah, 0
;int 16h
;mov ax, 3
;int 10h





;f:
;inc dl
;inc ebx
;mov di, bx
;mov [es:di], dl
;cmp bx, 0FFFFh
;jne g
;push es
;pop ax
;add ax, 0x1000
;push ax
;pop es
;g:
;cmp ebx, 1307200
;jne f

;call drawPixel




;ramonter
;mov ax, 1301h 
;mov bp, strR
;mov cx, lenstrR
;mov bl, 0Fh
;int 10h


jmp $

strR db 'Ramonter v0.01'
lenstrR = $ - strR



drawPixel:
mov di, 50h
mov [es:di], al
ret







times 510 - ($-7c00h) db 0
db 055h, 0AAh