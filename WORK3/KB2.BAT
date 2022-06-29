; @echo off
; goto compile
.model tiny
.code
.486

org 100h

_:
	jmp start

inthnd:
	sti

	push ax		; save ax, dx, ds, es, bx, di
	push dx		;  .
	push ds		;  .
	push es		;  .
	push bx		;  .
	push di		;  .

	in al,60h	; al = scan code

	push cs		; ds = es = cs
	pop ds		;  .
	push cs		;  .
	pop es		;  .

	lea di,buf	; write scan code in buf
	mov bl,al	;  .
	call h2		;  .

	mov ah,09h	; print buf
	lea dx,buf	;  .
	int 21h

	; signal keyboard it can proceed
	mov al,bl
	or al,10000000b
	out 61h,al
	and al,01111111b
	out 61h,al
	; signaled

	; signal PIC interruption processed
	mov al,20h
	out 20h,al
	; signaled

	cmp bl,01h	; if ESC pressed then exit
	jnz nxt1	;  .
	mov finish,bl	;  .

nxt1:
	pop di		; restore di, bx, es, ds, dx, ax
	pop bx		;  .
	pop es		;  .
	pop ds		;  .
	pop dx		;  .
	pop ax		;  .

	iret

buf	db	"__",13,10,"$"
old_cs	dw	0
old_ip	dw	0
finish	db	0

start:
	mov ax,3509h	; get int9 handler
	int 21h		;  es:bx -> handler

	mov [old_cs],es ; save old handler
	mov [old_ip],bx	;  .

	mov ax,2509h	; set int9 handler
	lea dx,inthnd	;  .
	int 21h		;  .

lp1:	mov al,finish	; while (finish == 0)
	test al,al	;  .
	jz lp1		;  .

	mov dx,[old_ip]	; restore old int9 handler
	mov ax,[old_cs]	;  .
	push ax		;  .
	pop ds		;  .
	mov ax,2509h	;  .
	int 21h

	ret

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
end _

; :compile
; tasm /m5 kb2.bat
; tlink /x/t kb2.obj
; del kb2.obj