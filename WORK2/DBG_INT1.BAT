; @echo off
; goto compile
.model tiny
.code
.486

org 100h

_:
	jmp start

inthnd:
	push bp		; save bp
	mov bp,sp	; bp = sp -> | bp | ip | cs | flags | ... |X|

	push bx		; save bx, di, ax, dx, ds, es
	push di		;  .
	push ax		;  .
	push dx		;  .
	push ds		;  .
	push es		;  .
	
	push cs		; ds = es = cs
	pop ds		;  .
	push cs		;  .
	pop es		;  .

	mov bx,[bp+4]	; bx = cs
	lea di,outbuf	; di -> outbuf
	call h4		; write bx in di
	
	mov bx,[bp+2]	; write ip in outbuf
	lea di,outbuf+5	;  .
	call h4		;  .
	
	mov ah,09h	; print string
	lea dx,outbuf	;  dx -> string
	int 21h		;  .
	
	pop es		; restore es, ds, dx, ax, di, bx
	pop ds		;  .
	pop dx		;  .
	pop ax		;  .
	pop di		;  .
	pop bx		;  .

	pop bp		; restore bp

	iret

outbuf	db	"____:____",13,10,"$"

h4:
	ror bx,8
	call h2
	ror bx,8
h2:
	mov al,bl
	shr al,4
	cmp al,10
	sbb al,69h
	das
	cld
	stosb
	mov al,bl
	and al,0fh
	cmp al,10
	sbb al,69h
	das
	stosb
	ret

start:
	mov ah,25h	; set interrupt
	mov al,1	;  al = intn
	lea dx,inthnd	;  dx -> handler
	int 21h		;  . // when called, cs will be eq to curr ds

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
	
	pushf		; save flags, deb_cs and postdbg (ip after debug)
	push cs		;  needed for iret in psp below
	lea cx,postdb	;  .
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
	
	nop		; without nop cpu execute next cmd with old flags

	retf		; start new prog using cs:ip from stack
	; end of correction

postdb:
	push cs		; restore ds
	pop ds		;  .
	mov ah,09h	; print string
	lea dx,msg	;  dx -> string
	int 21h		;  .

	ret

msg	db	"Finished.",13,10,"$"
fname	db	"hellwrd.com",0
	align (16)	; any segment register % 16 should be 0
psp:	iret	; restore cs:ip and flags of debugger from stack
	db	(256-1) dup(0)
prog	db	256 dup(0)

end _

; :compile
; tasm /m5 dbg_int1.bat
; tlink /x/t dbg_int1.obj
; del dbg_int1.obj