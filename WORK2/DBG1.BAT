; @echo off
; goto compile
.model tiny
.code
.486

org 100h

_:
	jmp start

inthnd:
	mov ah,02h
	mov dl,'!'
	int 21h
	iret

start:
	mov ah,25h	; set interrupt
	mov al,1	;  al = intn
	lea dx,inthnd	;  dx -> handler
	int 21h		;  .

	mov ax,3d00h	; open file (3d) to read (00)
	lea dx,fname	;  dx -> file name
	int 21h		;  ax = file handler

	mov bx,ax	; read file | bx = file handler
	mov ah,3fh	;  .
	mov cx,256	;  cx = len
	lea dx,prog	;  dx -> buffer
	int 21h		;  read
	
	mov ah,3eh	; file closing (bx = file handler)
	int 21h		;  .
	
	push cs		; save deb_cs and postdbg (ip after deb prog)
	lea cx,postdb	;  nedded for retf in psp below
	push cx		;  .

	xor cx,cx	; push(0)
	push cx		;  thus new prog will return in its psp beginning

	; correct registers for debugging prog
	push cs		; ax = deb_cs
	pop ax		;  .
	lea bx,psp	; bx -> psp
	shr bx,4	; bx = bx << 4  //paragraphs count
	add ax,bx	; ax = deb_cs + bx = new_cs
	push ax		; save for retf
	
	mov bx,100h	; save new_ip = 100h for retf
	push bx		;  .
	
	push ax		; ds = new_ds = new_ip
	pop ds		;  .
	
	pushf		; tf = 1
	pop ax		;  ax = flags
	or ax,100000000b	; raise tf in ax
	push ax		;  flags = ax
	popf		;  .

	retf		; start new prog using cs:ip from stack
	; end of correction

postdb:
	pushf		; tf = 0
	pop ax		;  .
	and ax,1111111011111111b
	push ax		;  .
	popf

	push cs		; restore ds
	pop ds		;  .
	mov ah,09h	; print string
	lea dx,msg	;  dx -> string
	int 21h		;  .

	ret

msg	db	"Finished.",13,10,"$"
fname	db	"hellwrd.com",0
	align (16)	; cs,ds % 16 = 0
psp:	retf
	db	(256-1) dup(0)
prog	db	256 dup(0)

end _

; :compile
; tasm /m5 dbg1.bat
; tlink /x/t dbg1.obj
; del dbg1.obj