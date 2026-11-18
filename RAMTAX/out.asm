; ####### $BOOT
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
mov dx, 0; disk A, head 0 (dl - disk, dh - head)
mov ch, 0; 10bit - cyl, 6bit - sector
mov cl, 2; sector
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
times 510 - ($ - 7c00h) db 0
db 055h, 0AAh; ƒ¿À‹ÿ≈ «¿√–”«◊»  Õ≈ »ƒ®“
ORG 500h
jmp HOME
var_QQ dd 0
var_NUM:
times 5 db 0
var_RAM:
 db 82, 97, 109, 111, 110, 116, 101, 114, 0

; ####### $MEAN WIDTH_T 80
; ####### func noth ASCIINumber : dword num, ptr byte _Str do:
fnv_ASCIINumber__Str dd 0
fnv_ASCIINumber_num dd 0
fnc_ASCIINumber:
; ####### until (num = 0) do:
til_1:
xor ebx, ebx
mov eax, [fnv_ASCIINumber_num]
xor edx, edx
cmp eax, ebx
mov eax, edx
jne cnd_0_0
inc al
cnd_0_0:
test eax, eax
jnz tle_1
; ####### equ *_Str = num % 10 + 0x30
xor ebx, ebx
mov ebx, 10
mov eax, [fnv_ASCIINumber_num]
xor edx, edx
div ebx
mov eax, edx
push eax
xor ebx, ebx
mov ebx, 0x30
pop eax
add eax, ebx
mov [fnv_ASCIINumber__Str]
mov di, dx
xor dx, dx
shr edx, 4
mov es, dx
mov [es:di]
; ####### equ num = num / 10
xor ebx, ebx
mov ebx, 10
mov eax, [fnv_ASCIINumber_num]
xor edx, edx
div ebx
mov [fnv_ASCIINumber_num], eax
; ####### end.
jmp til_1
tle_1:
; ####### end.
ret
; ####### func dword len : ptr byte _Str do:
fnv_len_i dd 0
fnv_len__Str dd 0
fnv_len_len dd 0
fnc_len:
; ####### init dword i
; ####### until *(_Str + i) = 0 do:
til_4:
mov ebx, [fnv_len_i]
mov eax, [fnv_len__Str]
add eax, ebx
push eax
xor ebx, ebx
xor eax, eax
pop eax
mov di, ax
xor ax, ax
shr eax, 4
push es, ax
mov eax, [es:di]
xor edx, edx
cmp eax, ebx
mov eax, edx
jne cnd_3_1
inc al
cnd_3_1:
test eax, eax
jnz tle_4
; ####### inc i
inc [fnv_len_i]
; ####### end.
jmp til_4
tle_4:
; ####### equ len = i
mov eax, [fnv_len_i]
mov [fnv_len_len], eax
; ####### end.
ret
; ####### HOME: 
HOME:
; ####### init str byte RAM = "Ramonter!"
; ####### init str 5 byte NUM
; ####### init dword QQ
; ####### equ QQ = 34
mov eax, 34
mov [var_QQ], eax
; ####### ASCIINumber{QQ, &NUM}
mov eax, [var_QQ]
push [fnv_ASCIINumber_num]
mov [fnv_ASCIINumber_num], eax
mov eax, var_NUM
push [fnv_ASCIINumber__Str]
mov [fnv_ASCIINumber__Str], eax
call fnc_ASCIINumber
mov eax, [fnv_ASCIINumber_ASCIINumber]
pop [fnv_ASCIINumber__Str]
pop [fnv_ASCIINumber_num]
pop eax
; ####### HEND.
hlt
HEND:
