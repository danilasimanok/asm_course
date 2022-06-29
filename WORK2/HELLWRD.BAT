; @echo off
; goto compile
.model tiny
.486
.code

org 100h

helowd:
	lea dx,hell
	mov ah,09h
	int 21h
	nop		; see debugger for explainations
	ret

hell	db	'Hello, world!',13,10,"$"
end helowd

; :compile
; tasm /m5 hellwrd.bat
; tlink /x/t hellwrd.obj
; del hellwrd.obj