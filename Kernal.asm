extrn _getorder:near
extrn _order:near
extrn _filename:near
extrn _comparerootrecord:near
extrn _find:near
extrn _numtochar:near
extrn _ans:near
extrn _ischar:near
extrn _savePCB:near
extrn _PCBlist:near
extrn _proindex:near
extrn _pronum:near
extrn _choosepro:near
extrn _initialPCB:near
_TEXT segment byte public 'CODE'
DGROUP group _TEXT,_DATA,_BSS
assume cs:_TEXT
org 100h
start:
	mov ax,0
	mov es,ax
	mov ax,cs
	mov word ptr es:[132],offset systemcall
	mov word ptr es:[134],ax
	call SetTimer
p:
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov ss,ax
	mov sp,100h
	mov word ptr ds:[fail],0
	call near ptr _clear
	call near ptr _print
	call near ptr _getorder
	cmp word ptr ds:[fail],1
	je res
	call run
res:
	call near ptr _restart
	fail dw 0
	ret_save dw 0
	ds_save dw 0
	cs_save dw 0
	ip_save dw 0
	flag_save dw 0
	ss_save dw 0
	sp_save dw 0
	ax_save dw 0
SetTimer:
	mov al,34h			; 设控制字值
	out 43h,al				; 写控制字到控制字寄存器
	mov ax,59659	; 每秒20次中断（50ms一次）
	out 40h,al				; 写计数器0的低字节
	mov al,ah				; AL=AH
	out 40h,al				; 写计数器0的高字节
	ret
Timer:
	call save
	call near ptr _choosepro
	cmp ax,0 ;当所有用户程序都结束，重启内核
	je restartker
	jmp restartpro
restartker: 
	mov bx,0
	mov es,bx
	pop word ptr es:[38]
	pop word ptr es:[36]
	pop word ptr es:[34]
	pop word ptr es:[32]
	mov si,offset _proindex
	mov word ptr ds:[si],0
	mov si,offset _pronum
	mov word ptr ds:[si],0
	mov al,20h
	out 20h,al
	out 0a0h,al
	call near ptr _restart
iffinish:
	push ax
	push bx
	push dx
	push si
	mov bx,ss
	cmp bx,base_of_Kernal
	je proend
	jmp .ret
proend:
	mov si,offset _proindex
	mov ax,word ptr ds:[si]
	mov bx,32
	mul bx
	mov bx,offset _PCBlist
	add bx,ax
	mov word ptr ds:[bx+30],2
.ret:
	pop si
	pop dx
	pop bx
	pop ax
	ret
save: ;此时栈顶为被中断程序的FLAG，CS，IP，call save的返回地址
	push ds
	push cs
	pop ds ;将ds置为内核的ds
	call iffinish
	pop word ptr ds:[ds_save] 
	pop word ptr ds:[ret_save] ;保存save过程的返回地址
	mov word ptr ds:[ss_save],ss
	mov word ptr ds:[sp_save],sp
	add word ptr ds:[sp_save],6
	push dx
	push cx
	push bx
	push ax
	push word ptr ds:[sp_save]
	push bp
	push si
	push di
	push word ptr ds:[ss_save]
	push es
	push word ptr ds:[ds_save]
	call near ptr _savePCB ;保存各个寄存器
	pop cx ;将栈还原到程序发生中断之前的状态
	pop cx
	pop cx
	pop cx
	pop cx
	pop cx
	pop cx
	pop cx
	pop cx
	pop cx
	pop cx
	pop cx
	pop cx
	pop cx
	push word ptr ds:[ret_save]
	ret
pp:
	mov ax,0b800h
	mov es,ax
	mov byte ptr es:[0],'B'
	mov byte ptr es:[1],07h
	jmp $
restartpro:
	mov si,offset _proindex
	mov ax,word ptr ds:[si]
	mov bx,32 ;一个PCB结构体大小为32字节
	mul bx
	mov bx,ax
	add bx, offset _PCBlist ;bx为标号为proindex的PCB的首地址
	mov ax,word ptr ds:[bx+22] ;保存新用户程序的CS，IP，FLAG
	mov word ptr ds:[ip_save],ax
	mov ax,word ptr ds:[bx+24]
	mov word ptr ds:[cs_save],ax
	mov ax,word ptr ds:[bx+26]
	mov word ptr ds:[flag_save],ax
	
	mov ax,word ptr ds:[bx+4] ;切换为新用户程序的栈
	mov ss,ax
	mov sp,word ptr ds:[bx+12]
	
	mov ax,word ptr ds:[bx+14]
	mov word ptr ds:[ax_save],ax
	
	mov ax,word ptr ds:[bx]
	mov word ptr ds:[ds_save],ax
	push word ptr ds:[bx+2] ;恢复新用户进程的寄存器
	push word ptr ds:[bx+6]
	push word ptr ds:[bx+8]
	push word ptr ds:[bx+10]
	push word ptr ds:[bx+16]
	push word ptr ds:[bx+18]
	push word ptr ds:[bx+20]
	pop dx
	pop cx
	pop bx
	pop bp
	pop si
	pop di
	pop es
	push word ptr ds:[flag_save]
	push word ptr ds:[cs_save]
	push word ptr ds:[ip_save]
	push word ptr ds:[ax_save]
	mov ax,word ptr ds:[ds_save] ;保存ds，通过ax作为中介
	mov ds,ax
	mov al,20h
	out 20h,al
	out 0a0h,al
	pop ax ;最后保存作为中介及发送EOI的ax
	iret

systemcall:
	cmp ah,0
	je call0
	cmp ah,2
	je call2
	cmp ah,3
	je call3
poi:
	jmp $
call0:
	call near ptr printnum
call2:
	call near ptr upper
call3:
	call near ptr lower
printnum: ;输入为dh、dl、bx
	push es
	push dx
	push ax
	mov ax,0b800h
	mov es,ax
	push dx
	push bx
	call near ptr _numtochar
	pop bx
	pop dx
	push bx
	mov si,offset _ans
shownum:
	push dx
	mov al,dh
	mov bl,80
	mul bl
	mov dh,0
	add ax,dx
	mov bx,2
	mul bx
	mov bx,ax
	mov al,byte ptr [si]
	pop dx
	inc dl
	cmp al,0
	je endprintnum
	mov byte ptr es:[bx],al
	mov byte ptr es:[bx+1],07h
	inc si
	jmp shownum
endprintnum:
	mov al,20h
	out 20h,al
	out 0a0h,al
	pop bx
	pop ax
	pop dx
	pop es
	pop cx
	iret

upper: ;输入为es、bx,cx
	push bx
	push cx
uchange:
	mov ah,0
	mov al,byte ptr es:[bx]
	push cx
	push bx
	push ax
	call near ptr _ischar
	cmp ax,1
	pop ax
	pop bx
	pop cx
	jne touchange
	sub byte ptr es:[bx],32
touchange:
	inc bx
	loop uchange
endupper:
	mov al,20h
	out 20h,al
	out 0a0h,al
	pop cx
	pop bx
	pop cx
	iret
lower: ;输入为es、bx,cx
	push bx
	push cx
lchange:
	mov ah,0
	mov al,byte ptr es:[bx]
	push cx
	push bx
	push ax
	call near ptr _ischar
	cmp ax,2
	pop ax
	pop bx
	pop cx
	jne tolchange
	add byte ptr es:[bx],32
tolchange:
	inc bx
	loop lchange
endlower:
	mov al,20h
	out 20h,al
	out 0a0h,al
	pop cx
	pop bx
	pop cx
	iret
Key:
	push es
	push ax
	in al,60h
	cmp al,1
	jne endKey
	mov ax,0b800h
	mov es,ax
	mov byte ptr es:[(80*12+39)*2],'O'
	mov byte ptr es:[(80*12+39)*2+1],07h
	mov byte ptr es:[(80*12+39)*2+2],'U'
	mov byte ptr es:[(80*12+39)*2+3],07h
	mov byte ptr es:[(80*12+39)*2+4],'C'
	mov byte ptr es:[(80*12+39)*2+5],07h
	mov byte ptr es:[(80*12+39)*2+6],'H'
	mov byte ptr es:[(80*12+39)*2+7],07h
	mov byte ptr es:[(80*12+39)*2+8],'!'
endKey:
	mov al,20h
	out 20h,al
	out 0a0h,al
	pop ax
	pop es
	iret
	rootsector dw 20	;根目录起始扇区
	numofroot db 14     ;根目录扇区数
	offset_of_pro equ 100h
	tempoffset equ 5000h
	base_of_pro equ 2000h
	base_of_Kernal equ 1000h ;内核段地址
	base equ 1000h
public _runpro
_runpro proc
call near ptr _clear
mov word ptr [rootsector],20
mov byte ptr [numofroot],14
readroot: ;读根目录
	mov ax,base
	mov es,ax
	mov bx,tempoffset
	mov ax,[rootsector]
	mov cl,1
	call readsector
	dec byte ptr [numofroot]
	je loadfail ;如果读完根目录还没找到文件，则读取失败
	inc word ptr [rootsector]
compare: ;比较当前记录的文件名是否为要找的文件
	call near ptr _comparerootrecord
	cmp ax,0
	je readroot
	jmp getprogram
readsector: ;相当于一个有参数的函数，参数为es，bx，扇区号，扇区数。
	push ax
	dec ax
	push bp
	mov bp,sp
	sub sp,2
	mov byte[bp-2],cl
	push bx
	mov bl,18
	div bl
	mov cl,ah
	inc cl
	mov ch,al
	shr ch,1
	mov dh,al
	and dh,1
	mov dl,0
	mov al,byte[bp-2]
	mov ah,2
	pop bx
	int 13h
	add sp,2
	pop bp
	pop ax
	ret
loadfail:
	mov word ptr ds:[fail],1
	ret
getprogram:
	mov dx,base_of_pro
	add dx,word ptr ds:[offsetpos]
	mov es,dx
	mov bx,offset_of_pro
	push ax
	add ax,32
	mov cl,1
	call readsector
	mov ax,base
	mov es,ax
readfat:
	mov ax,2
	mov cl,9
	mov bx,tempoffset
	call readsector
	mov bx,offset_of_pro
	pop ax
loadother:
	mov cl,1
	mov dx,base
	mov es,dx
	add bx,512
	push bx
	call near ptr _find
	pop bx
	cmp ax,0ff8h
	jae loadfinish
	add ax,32
	mov dx,base_of_pro
	add dx,word ptr ds:[offsetpos]
	mov es,dx
	call readsector
	jmp loadother
loadfinish:
	mov dx,base_of_pro
	add dx,word ptr ds:[offsetpos]
	mov es,dx
	mov dx,offset_of_pro
	push dx
	push es
	call near ptr _initialPCB
	pop cx
	pop cx
	mov si,offset _proindex
	inc word ptr ds:[si]
	mov si,offset _pronum
	inc word ptr ds:[si]
	add word ptr ds:[offsetpos],100h
	ret
ppp:
public _ppp
_ppp proc
	mov ax,0b800h
	mov es,ax
	mov byte ptr es:[0],'B'
	mov byte ptr es:[1],07h
	jmp $
_ppp endp
_runpro endp
jmppos dd 0
offsetpos dw 0
run: ;运行第一个用户程序
	mov si,offset _proindex
	mov word ptr ds:[si],0
	mov word ptr ds:[jmppos],offset_of_pro
	mov word ptr ds:[jmppos+2],base_of_pro
	mov bx,0
	mov es,bx
	mov bx,cs
	push word ptr es:[32] ;设置时钟中断向量及键盘中断向量
	push word ptr es:[34]
	push word ptr es:[36]
	push word ptr es:[38]
	mov word ptr es:[32],offset Timer
	mov word ptr es:[34],bx
	mov word ptr es:[36],offset Key
	mov word ptr es:[38],bx
	jmp dword ptr ds:[jmppos]
public _read
_read proc
	push es
	push ds
	mov cx,100
	mov si,offset _order
input:
	mov ah,0
	int 16h
	cmp al,8
	je back
	cmp al,13
	je infinish
	mov [si],al
	mov bl,0
	mov ah,0eh
	int 10h
	inc si
	loop input
back:
	cmp si,offset _order
	je input
	push cx
	dec si
	mov byte ptr [si],0
	mov ah,3
	mov bh,0
	int 10h
	dec dl
	mov ah,2
	int 10h
	mov cx,1
	mov ax,0a00h
	int 10h
	pop cx
	jmp input
infinish:
	pop ds
	pop es
	ret
_read endp
public _print
_print proc
push es
push ds
mov ax,1301h
mov bl,07h
mov bh,0
mov dh,1
mov dl,1
mov cx,message1length
mov bp,offset message1
int 10h
pop ds
pop es
ret
_print endp
public _clear
_clear proc
	push es
	push ds
	mov ah,06h
	mov al,0
	mov bh,07h
	mov ch,0
	mov cl,0
	mov dh,24
	mov dl,79
	int 10h
	mov dx,0
	mov ah,2
	int 10h
	pop ds
	pop es
	ret
_clear endp
public _restart
_restart proc
mov word ptr ds:[offsetpos],0
mov si,offset _proindex
mov word ptr ds:[si],0
mov si,offset _pronum
mov word ptr ds:[si],0
pop cx
jmp p
_restart endp
message1:db 'Please enter command'
message1length equ $-message1
_TEXT ends
_DATA segment word public 'DATA'
_DATA ends
_BSS	segment word public 'BSS'
_BSS ends
end start
	
	
	