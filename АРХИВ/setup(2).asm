org 7c00h
;_MAX_ = 640 * 480



start:
cli
xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 07c00h
sti

mov al, 3 ;видеорежим
int 10h
mov dh, 0 ;строка
mov dl, 0 ;ряд
xor bh, bh
int 10h

mov al, 12h 
int 10h

pusha

xor        bx,bx
mov        ax,dx          
lea        еах,[еах+еах*4]   
shl        ах,4           
                   
push       cx
shr        cx,3         
add        ax,cx          
mov        di,ax              
pop        сх
and        cx,07h            
mov        bx,0080h
shr        bx,cl            
mov        dx,03CEh     
                                  
mov        ax,0F01h      
                               
out        dx,ax          
mov        ax,bp
shl        ax,8           
out        dx,ax            
mov        al,08           
mov        ah,bl        
                            
out        dx,ax          
mov        ah, es:[di]

mov        es:[di], ah 

рора


;mov ax, 0xA000
;mov es, ax
;xor di, di
;mov ax, 0x0F
;jmp print

;print:
;stosw
cmp di, 123h
;jbe printend
;inc di
;jmp print
;printend:
jmp $






strR db 'Ramonter v0.01'
lenstrR = $ - strR







times 510 - ($-7c00h) db 0
db 055h, 0AAh