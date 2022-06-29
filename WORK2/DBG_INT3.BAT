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

	mov bx,[bp+4]	; bx = cs of prog
	lea di,outbuf	; di -> outbuf
	call h4		; write bx in di
	
	mov bx,[bp+2]	; write ip of prog in outbuf
	dec bx		; // after cmd restoration it should be reexecuted
	mov [bp+2],bx	; //  and current ip of prog -> cmd after breakpoint
	lea di,outbuf+5	;  .
	call h4		;  .
	
	mov ah,09h	; print string
	lea dx,outbuf	;  dx -> string
	int 21h		;  .

	mov bx,[bp+2]	; bx = improved ip of prog
	mov ax,[bp+4]	; es = cs of prog
	push ax		;  .
	pop es		;  .
	mov al,oldbyte	; restore cmd
	mov [es:bx],al	;  .
	
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
	mov al,3	;  al = intn
	lea dx,inthnd	;  dx -> handler
	int 21h		;  . // NB!: int 3 -> next cmd

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

	; set break point
	xor bx,bx	; bx = prog + [cmdnum]
	mov bx,[cmdnum]	; .
	add bx,offset prog	; .
	mov al,[bx]	; al = old command
	mov oldbyte,al	; save old command
	mov al,0cch	; al = int 3
	mov [bx],al	; replace old command with "int 3"
	; break point set
	
	push cs		; save deb_cs and postdbg (ip after debug)
	lea cx,postdb	;  needed for retf in psp below
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
	
	retf		; start new prog using cs:ip from stack
	; end of correction

postdb:
	push cs		; restore ds
	pop ds		;  .
	mov ah,09h	; print string
	lea dx,msg	;  dx -> string
	int 21h		;  .

	ret

cmdnum	dw	5
oldbyte	db	0
msg	db	"Finished.",13,10,"$"
fname	db	"hellwrd.com",0
	align (16)	; any segment register % 16 should be 0
psp:	retf	; restore cs, ip of debugger from stack
	db	(256-1) dup(0)
prog	db	256 dup(0)

end _

; :compile
; tasm /m5 dbg_int3.bat
; tlink /x/t dbg_int3.obj
; del dbg_int3.obj