mov		cx, 2
	mov		bx, 0x0410 - 0x2200
load_sectors:
    	mov 		ax, 0FFFFh
    	mov 		es, ax
	push		cx
    	mov 		dh, cl      ; Головка
	and		dh, 0x1
    	mov 		cl, ch      ; Цилиндр
	shr		cl, 1
	mov 		ax, 0FFFFh
    	mov 		es, ax
    	mov 		ah, 0x02
    	mov 		al, 18      ; Количество секторов
    	mov 		cl, 1      ; Сектор (следующий после загрузчика)
    	add		bx, 0x2200 ; Адрес загрузки (ES:BX = 0xFFFF:0x0010)
	push		bx
    	int 0x13
	jc error
	pop		bx
	pop		cx
	inc		cx
	cmp		cx, 7
	jl		load_sectors




; ###### Загрузка Root Directory (20-й сектор - начало) ######
	xor		ax, ax
    	mov 		es, ax
    	mov 		ah, 0x02
    	mov 		al, 14      ; Количество секторов
    	mov 		ch, 0      ; Цилиндр
    	mov 		dh, 1      ; Головка
    	mov 		cl, 3      ; Сектор
    	mov 		bx, 0x7E00 ; Адрес загрузки (ES:BX = 0x0000:0x7E00)
    	int 0x13
	
; ###### Поиск kernel.bin ######
	mov		ax, 0x7E0
	mov		ds, ax
	mov		di, KERNEL_NAME
	xor		ax, ax
	mov		es, ax
	mov		si, ax
kernel_search:
	mov		ecx, 11 ; symbols
	push		di
	push		si
	repe 	cmpsb
	pop		si
	pop		di
	jz		found_kernel
	add		si, 0x20 ; file header size
	jmp		kernel_search
found_kernel:
	add		si, 0x1A ; first cluster
	mov		ax, word ds:[si]
	mov		word [KERNEL_CLUSTER], ax
	
; ###### Загрузка FAT ######
	xor		ax, ax
    	mov 		es, ax
    	mov 		ah, 0x02
    	mov 		al, 9       ; Количество секторов
    	mov 		ch, 0      ; Цилиндр
    	mov 		dh, 0      ; Головка
    	mov 		cl, 2      ; Сектор (следующий после загрузчика)
    	mov 		bx, 0x7E00 ; Адрес загрузки (ES:BX = 0x0000:0x7E00)
    	int 0x13

	mov		bx, word [KERNEL_CLUSTER]
	mov		ax, 0x7E0
	mov		si, ax

	; #### Делим на 1.5 ####
	lea		bx, [bx+bx*2]
	shr		bx, 1
	mov		eax, dword [bx+si]
	jnc		even_cluster
	shr		eax, 12
even_cluster:
	and		ax, 0FFFh



; #### AX - кластер ####
read_cluster:
	shl		ax, 3
	add		ax, 33
	; ### EAX = номер сектора (с нулевого) ###
	cwd
	mov		bx, 80
	div		bx
	mov		cl, dl
	shr		cl, 1
	xor		dh, dh
	adc		dh, 0
	inc		cl
	mov		ch, al
	; ### CH = цилиндр ###
	; ### DH = головка ###
	; ### CL = сектор ###
	
	
	
    	mov 		bx, 0FFFFh
    	mov 		es, bx
    	mov 		ah, 0x02
    	mov 		al, 8      ; Количество секторов
    	mov 		bx, 0x0010 ; Адрес загрузки (ES:BX = 0xFFFF:0x0010)	

    	int 0x13