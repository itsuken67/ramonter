use16
org 0x7c00

start:
    mov al, '&'
    mov ah, 0x0E; номер функции BIOS
    mov bh, 0; страница видеопамяти
    int 0x10; выводим символ
 
    push  es
    push  ds
    mov   ax, 0x100         ; сегмент куда пишем
    mov   es, ax
    mov bx, 0; адрес куда пишем
    mov   ch, 0; дорожка 0
    mov   cl, 2   ; начиная с сектора 2
    mov   dl, 0x80; номер диска
    mov   dh, 0; номер головки
    mov   ah, 2; номер функции
    mov   al, 1;считать 1 сектор
    int   0x13
    
    jnc .no_error
    mov al, '!'
    mov ah, 0x0E; номер функции BIOS
    mov bh, 0; страница видеопамяти
    int 0x10; выводим символ
    jmp $
    .no_error:
    
    pop   ds
    pop   es
    
    
    jmp 0x100:0
   
finish:
    times 0x1FE-finish+start db 0; тут выравниваем блок кода до размера сектора(512 байт)
    db 0x55, 0xAA; сигнатура загрузочного сектора
    
main:
    mov al, '.'
    mov ah, 0x0E; номер функции BIOS
    mov bh, 0; страница видеопамяти
    int 0x10; выводим символ
    jmp 0:0x7c00