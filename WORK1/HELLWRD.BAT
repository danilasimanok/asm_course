; @echo off
; goto compile
.model tiny
.486
.code

org 7c00h
helowd:
	mov dl,0
	mov dh,0
prloop:
	cmp dl,14
	je  l1

	mov ah,02h	; move cursor
	mov bh,0
	int 10h
	
	lea si,hel
	mov bl,dl
	mov al,[si][bx]	; load next char
	mov bx,0
	
	mov ah,0ah	; print char	
	mov bh,0	
	mov cx,1
	int 10h
	
	inc dl
	jmp prloop
l1:	
	jmp l1
hel	db	'Hello, world!'
	db	(510-($-helowd)) dup(0)
	db	55h,0aah
end helowd

; :compile
; tasm /m5 hellwrd.bat
; tlink /x/t hellwrd.obj, hellwrd.bin
; del hellwrd.obj