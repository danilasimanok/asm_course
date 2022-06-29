; @echo off
; goto compile
.model tiny
.code
.486

org 100h

_:
	jmp start

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
;	mov ah,0	; keyboard read
;	int 16h		; al = ascii code, ah = scan code

	push cx		; save cx, bx, di, es
	push bx		;  .
	push di		;  .
	push es		;  .

	xor ax,ax	; ax = es = 0
	push ax		;  .
	pop es		;  .

tstq:	mov cx,[es:41ah]	; cx = hd ptr
	mov bx,[es:41ch]	; bx = tl ptr
	cmp cx,bx	; if cx == bx then queue is empty and we should wait
	je tstq		;  .

	mov di,cx	; di = char info ptr
	add di,400h	;  .
	mov ax,[es:di]	; ax = char info

	add cx,2	; move hd
	cmp cx,3eh	; if out of bounds return in queue buf beginning
	jne savhd	;  .
	mov cx,1eh	;  .
savhd:	mov [es:41ah],cx	; save hd

	pop es		; restore es, di, bx, cx
	pop di		;  .
	pop bx		;  .
	pop cx		;  .

;	!!!!!!

	mov dx,ax	; save char info in dx
	lea di,buffer	; di -> buffer
	mov bl,dl	; bl = scan code
	call h2		; write bl in di

	lea di,buffer+3	; di -> after SPACE
	mov bl,dh	; bl = ascii code
	call h2		; -//-

	lea di,buffer+8 ; di -> last _
	mov [di],dl	; write symbol itself
	
	mov cx,dx	; save char info in cx (for exit)

	mov ah,09h	; print buffer
	lea dx,buffer	;  .
	int 21h		;  .

	cmp ch,01	; repeat until ESC pressed
	jnz start	;  . (if != then exit)
	ret

buffer	db	"__ __ - _",13,10,"$"

end _

; :compile
; tasm /m5 kb1.bat
; tlink /x/t kb1.obj
; del kb1.obj