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
mov al, 17
xor bx, bx
mov ah, 02h
int 13h

mov dl, 0
mov dh, 1
mov bx, 0x2700
mov ch, 0
mov cl, 1
mov al, 18
mov ah, 02h
int 13h






jmp 0080:0000
jmp $

fd db 'error!'

times 510 - ($-7c00h) db 0
db 055h, 0AAh ;ДАЛЬШЕ ЗАГРУЗЧИК НЕ ИДЁТ

org 0x500


jmp home

const_string db 'Ramonter!', 0

length:
	mov		dword [bx + si + 4], 0
	mov 		eax, [bx + si]
	mov 		edx, [bx + si+ 4]
	add 		eax, edx
	push 	bx
	mov 		bx, ax
	mov 		al, [bx]
	pop	 	bx
	test 		al, al	
	jz 		LENGTH_TIL_END
	LENGTH_TIL:
	inc 		dword [bx+si+4]
	mov 		eax, [bx + si]
	mov 		edx, [bx + si+ 4]
	add 		eax, edx
	push 	bx
	mov 		bx, ax
	mov 		al, [bx]
	pop	 	bx
	test 		al, al	
	jnz 		LENGTH_TIL
	LENGTH_TIL_END:
	mov 		eax, [bx + si+ 4]
	mov 		[bx + si], eax
	xor 		eax, eax
	mov 		[bx + si+ 4], eax
	ret


delay_ms_bios:
    pushad
    mov ah, 86h
    mov cx, 0
    mov dx, 65000           ; 1000 мкс = 1 мс (можно умножить на N)
    int 15h
    popad
    ret





home: ; ####### HERE THE MAIN PROGRAM STARTS #######
	mov 		al, 0dh ; ## 320x200, 16 colors ##
	mov 		ah, 0 ; videomode
	int		10h


	cli
	xor		ax, ax
	mov		es, ax
	mov		di, 70h
	mov		ax, mouse_irq
	mov 		[es:di], ax
	mov		ax, 0
	mov		[es:di+2], ax
	sti



; ##### RED #####
;	mov		dx, 3C4h ; ### PLANAR ADDRESSING ###
;	mov		al, 02h
;	out		dx, al
;	inc 		dx
;	mov		al, 00000100b
;	out		dx, al

	mov 		edi, 40 * 199 ; ### LAST LINE ###
	mov 		ax, 0A000h
	mov 		es, ax	
	xor		ebx, ebx

jmp SKIP_ALLTHEERERJERJERKEKERER
BYTES_IN_WIDTH = 32
; ##### PARABOLA #####
	mov 		ecx, 200
	push		ecx
	xor		ah, ah
DRAW:
	mov		si, image_bmp + 3Eh ; ### PICTURE ###	
ALL_LINES_DRAW:
	push		ecx
	mov 		ecx, BYTES_IN_WIDTH
ONE_LINE_DRAW: 
	mov		al, [si]
	or		[es:di], al
	inc		di
	inc		si		;#### MEMCPY ####
	loop		ONE_LINE_DRAW
	pop		ecx 		; #### LINES IN ECX ####
	sub		di, 40 + BYTES_IN_WIDTH 		; #### TO THE BEG ON LINE ####
	loop		ALL_LINES_DRAW
	
; ###### RED COLOR DRAWING ######
;	mov		dx, 3C4h ; ### PLANAR ADDRESSING ###
;	mov		al, 02h
;	out		dx, al
;	inc 		dx
;	mov		al, 00001100b
;	out		dx, al

	
; ##### ASCII DISPLAY TEST #####



SKIP_ALLTHEERERJERJERKEKERER:

	
	  ; Команда "включить второе устройство" (мышь)
	call		wait_input
	mov		al, 0A8h
	out		64h, al
	 ; Команда "отправить на мышь"
	call		wait_input
	mov		al, 0D4h
	out		64h, al
  	 ; Команда "установить стандартные параметры"
	call		wait_input
	mov		al, 0F6h
	out		60h, al
	call		wait_ack

	call		wait_input
	mov		al, 0D4h
	out		64h, al
 	; Команда "включить отчеты"
	call		wait_input
	mov		al, 0F4h 
	out		60h, al
	call wait_ack ; ### WAITING FOR AN ANSWER FOR 0xFF AND 0xF4 ###

	call wait_input
    	mov al, 0x20       ; Читать байт команд контроллера
    	out 0x64, al
    	call wait_output
    	in al, 0x60
   	or al, 0x02        ; Включить IRQ12
    	call wait_input
  	mov bl, al
    	mov al, 0x60       ; Записать байт команд
   	out 0x64, al
   	call wait_input
    	mov al, bl
    	out 0x60, al

	; здесь нужно проверить CF, вдруг ошибка


	;call pixel ; #### PLACE A DOT ####
	
	

; ##### BCD OPERATIONS #####

	jmp $

; ####### MOUSE #######

;wait_input:
;	in		al, 64h
;	test		al, 2 ; #### buffer is busy
;	jnz		wait_input
;	ret



wait_input:
    		push cx
    		mov cx, 10h  ; Счётчик
.loopwait_input:
   		 in al, 64h
    		test al, 2
   		 jz .donewait_input
    		loop .loopwait_input
.donewait_input:
   		 pop cx
    		ret



wait_ack:
	call 		wait_output
	in 		al, 60h
	cmp 		al, 0FAh ; #### ACK code
	jne		wait_ack
	ret

pixel: ; ##### PLACE A DOT #####
	pusha

	mov 		ax, [PIXEL_Y]
	imul 		ax, 320
	add 		ax, [PIXEL_X]

;#### MOD (% 8) ####
	mov 		cl, al
	and 		cl, 0111b
	shr 		ax, 3
	mov 		di, ax
	mov 		al, 010000000b
	shr 		al, cl ; ### AL - THE BYTE THE WRITE ###

	xor		[es:di], al
	popa
	ret

PIXEL_X dw 0
PIXEL_Y dw 0

;wait_output:
	in		al, 64h
	test		al, 1 ; #### has data
;	jz		wait_output
	ret

wait_output:
    	push 	ecx
    	mov 		ecx, 10h
.loop:
    	in 		al, 64h
    	test 		al, 1           ; Есть данные?
    	jz 		.next             ; Если нет, пропускаем
    	test 		al, 20h         ; Данные от мыши (бит 5)?
    	jnz 		.done            ; Если да, выходим
.next:
    	loop 		.loop
.done:
    	pop 		ecx
    	ret



MOUSE_FLAGS db 0
MOUSE_X dw 	160
MOUSE_Y dw 	100
MOUSE_BYTE db 0
DELTA_X_STR db 0, 0, 0, 0
DELTA_Y_STR db 0, 0, 0, 0
DELTA_BEG db 0 ; ### THE LAST ALTERED BYTE ###

mouse_irq:
	pusha
	call		wait_output
	jz		mouse_end ; ##### NO DATA FOR MOUSE #####
	in		al, 60h
	cmp 	[MOUSE_BYTE], 2
	jz		mouse_byte_2
	cmp		[MOUSE_BYTE], 1
	jz		mouse_byte_1
	
mouse_byte_0: ; ##### FLAGS #####
	mov		[MOUSE_FLAGS], al
	inc		[MOUSE_BYTE]
	jmp		mouse_end
mouse_byte_1: ; ##### DELTA_X #####
	movzx	bx, [DELTA_BEG]
	mov		[bx + DELTA_X_STR], al 
	inc		[MOUSE_BYTE]
	jmp		mouse_end

mouse_byte_2: ; ##### DELTA_Y #####

	movzx	bx, [DELTA_BEG]
	mov		[bx + DELTA_Y_STR], al 
	mov		[MOUSE_BYTE], 0
	call		mouse_cursor
	

mouse_end:
	mov		al, 20h
	out		20h, al
	out		40h, al
	popa
	iret

mc_min = 2

mouse_cursor:	
; ##### DELTA_BEG WITHIN THE SCOPE 0-3 #####
	mov		dx, [MOUSE_X]
	inc		[DELTA_BEG]
	test		[DELTA_BEG], 11111100b
	jz		mc_delta_lss4
	mov		[DELTA_BEG], 0
mc_delta_lss4:

	mov		eax, dword [DELTA_X_STR] ; ### SUMMING LAST 4 X DELTAS ###
	mov		bx, ax
	add		bl, bh
	shr		eax, 16
	add		al, ah
	add		al, bl
	movsx	ax, al
	; #### IS NEGATIVE ####
	js		mouse_cursor_Xnegative
	; ## POSITIVE ##
	sub		ax, mc_min
	jle		mcur_XSKIP ; ### IF LESS THAN 4 OR EQUAL TO IT ###
	jmp		mcur_addDeltaX
mouse_cursor_Xnegative:
	; ## NEGATIVE ##
	add		ax, mc_min
	jbe		mcur_XSKIP 
mcur_addDeltaX:
	add		dx, ax ; #### DX IS NOW NEW MOUSE X ####
mcur_XSKIP: ; #### GOING THERE IS DELTA X IS TOO SMALL ####


	mov		ax, [MOUSE_Y]
	mov		ecx, dword [DELTA_Y_STR] ; ### SUMMING LAST 4 X DELTAS ###
	mov		bx, cx
	add		bl, bh
	shr		ecx, 16
	add		cl, ch
	add		cl, bl
	movsx	cx, cl
	; #### IS NEGATIVE ####
	js		mouse_cursor_Ynegative
	; ## POSITIVE ##
	sub		cx, mc_min
	jle		mouseYLlsOK ; ### IF LESS THAN 4 OR EQUAL TO IT ###
	jmp		mcur_addDeltaY
mouse_cursor_Ynegative:
	; ## NEGATIVE ##
	add		cx, mc_min
	jbe		mouseYLlsOK ; #### IF DELTA Y IS TOO SMALL THEN WE SKIP CHECKING FOR BOUNDARIES #### 
mcur_addDeltaY:
	sub		ax, cx
	

; #### NOW AX IS NEXT MOUSE Y AND DX HAS MOUSE X ####
	

; #### MOUSE Y ####
	cmp		ax, 199
	jle		mouseYRlsOK
	mov		ax, 199	
	mouseYRlsOK:
	test		ax, 0F000h
	jz 		mouseYLlsOK
	xor		ax, ax	
mouseYLlsOK:

; #### MOUSE X ####
	cmp		dx, 319
	jle		mouseXRlsOK
	mov		dx, 319
mouseXRlsOK:
	test		dx, 0F000h
	jz 		mouseXLlsOK
	xor		dx, dx
mouseXLlsOK:



	test		[MOUSE_FLAGS], 1 ; #### CHECK FOR LEFT BUTTON ####
	jnz		mouse_no_left_button
	call		pixel	
mouse_no_left_button:
	mov		[MOUSE_X], dx
	mov		[MOUSE_Y], ax
	mov		[PIXEL_X], dx
	mov		[PIXEL_Y], ax
	call 		pixel
.mouse_stop_draw:
	ret

	jmp $
	
	
; #### 0 - TRANSPARENT
; #### 1 - BLACK
; #### 2 - EXTRA (GRAY)
; #### 3 - WHITE
; #### 1 BYTE = 4 DOTS
; #### 1 LINE = 3 BYTES
; #### IMAGE SIZE = 48 BYTES
CURSOR_IMAGE db 	01010000b, 0, 0
db 					01010000b, 0, 0
db					01100100b, 0, 0
db					01100100b, 0, 0
db					01111001b, 0, 0
db					01111001b, 0, 0
db					01111110b, 01000000b, 0
db					01111110b, 01000000b, 0
db					01111111b, 10010000b, 0
db					01111111b, 10010000b, 0
db					01111111b, 11100100b, 0
db					01111111b, 11100100b, 0
db					01111111b, 11111001b, 0
db					01111111b, 11111001b, 0
db					01111111b, 11111010b, 01000000b
db					11111111b, 11111111b, 11000000b
image_bmp file 'trollface.bmp'






; ##### ANIMATION #####

	
	
ANIMATION:
	mov 		ecx, 8000
	rep 		stosb
	call 		delay_ms_bios
	inc		al
	mov		edi, ebx
	jmp		ANIMATION		


hlt


















_heap:
dd 		500h 
dd 8 dup	0
org 0

;		       0	    1		     2
; (смещение: нет - короткое - дальнее)
;тип-смещение-функция
;000
		mov		dword [si], eax
times 16 - ($ mod 16) db 077h

;001
		mov		dword [bx + si], eax
times 16 - ($ mod 16) db 077h

;010
		mov		dword [si + 10], eax
times 16 - ($ mod 16) db 077h

;011
		mov		dword [bx+ si + 10], eax
times 16 - ($ mod 16) db 077h

;020
		mov		dword [si + 1345], eax
times 16 - ($ mod 16) db 077h

;021
		mov		dword [bx + si + 1345], eax
times 16 - ($ mod 16) db 077h

;100
		mov		word [si], ax
times 16 - ($ mod 16) db 077h

;101
		mov		word [bx + si], ax
times 16 - ($ mod 16) db 077h

;110
		mov		word [si + 10], ax
times 16 - ($ mod 16) db 077h

;111
		mov		word [bx + si + 10], ax
times 16 - ($ mod 16) db 077h

;120
		mov		word [si + 1345], ax
times 16 - ($ mod 16) db 077h

;121
		mov		word [bx + si + 1345], ax
times 16 - ($ mod 16) db 077h

;200
		mov		byte [si], al
times 16 - ($ mod 16) db 077h

;201
		mov		byte [bx + si], al
times 16 - ($ mod 16) db 077h

;210
		mov		byte [si + 10], al
times 16 - ($ mod 16) db 077h

;211
		mov		byte [bx + si + 10], al
times 16 - ($ mod 16) db 077h

;220
		mov		byte [si + 1345], al
times 16 - ($ mod 16) db 077h

;221
		mov		byte [bx + si + 1345], al
times 16 - ($ mod 16) db 077h

;инициализация по регистру done!
;инициализация по значению done!
;инициализация по объекту done!
;произведение операции над объектом и константой (_obj, _byobj)
;произведение операции над двумя объектами (_2obj)
;запись по объекту
;запись по адресу
;вызов функции
;работа с циклами (until, while, cycle)
;
;булева переменная о наличии значения в регистре должна меняться на 1 после каждой выполненной операции вычисления и на 0 после любой другой операции
; таким образом, во время выполнения операции вычисления значение из регистра будет заноситься в кучу, если значение переменной равно 1
; идея: добавить в файл с байт кодом массив с названиями переменных, чтобы на них можно было ссылаться во время обработки кода на языке ассемблера
; мы можем загрузить весь массив целиком, и по ходу выполнения программы во время иницализации переменных каждому новому объекту мы будем присваивать смещение в массиве
; таким образом, во время обработки кода на ассемблере мы можем задать макросы с помощью директивы (название = [bx + si + смещение])
; либо мы можем заменять название сразу


;0000000000007c0d: (                    ): mov dword ptr ds:[bx+si+4], eax ; 66894004
;0000000000007c11: (                    ): mov dword ptr ds:[bx+si+45], eax ; 6689402d
;0000000000007c15: (                    ): mov word ptr ds:[bx+si+49], ax ; 894031
;0000000000007c18: (                    ): mov dword ptr ds:[bx+si+70], eax ; 66894046
;0000000000007c1c: (                    ): mov word ptr ds:[bx+si+74], ax ; 89404a
;0000000000007c1f: (                    ): mov word ptr ds:[bx+si+78], ax ; 89404e
;0000000000007c22: (                    ): mov dword ptr ds:[si+84], eax ; 66894454
;0000000000007c26: (                    ): add byte ptr ds:[bx+si], al ; 0000

;000
		mov		dword [si], 12345678h
times 16 - ($ mod 16) db 077h

;001
		mov		dword [bx + si], 12345678h
times 16 - ($ mod 16) db 077h

;010
		mov		dword [si + 10], 12345678h
times 16 - ($ mod 16) db 077h
