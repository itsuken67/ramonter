[bits 32]

global _shell_OFF
_shell_OFF:
cli
mov edi, 0x894
mov esi, _shell_OFF.real_mode
mov ecx, _shell_OFF.real_mode_end - _shell_OFF.real_mode
b1:
	sti
	lodsb
	stosb
	loop b1
	
    mov eax, cr0
    and eax, ~1          ; Сбросить бит PE (Protection Enable)
    mov cr0, eax


	xor ax, ax
	mov ds, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov bp, ax
	mov ax, 7c00h
	mov sp, ax

    ; 2. Перейти в реальный режим (Far Jump)
    jmp 0x0000:0x894

[bits 16]
_shell_OFF.real_mode:


    ; 3. Восстановить сегменты как в Real Mode
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

    cli
    hlt
_shell_OFF.real_mode_end: