; @echo off
; goto compile

.model tiny
.code
.486
org 100h
start:
	mov ah,3dh	; file opening
	mov al,0	;  open mode = read
	lea dx,fname	;  set up file to read
	int 21h		;  ax = file handler

	mov bx,ax	; file reading | bx = file handler
	mov ah,3fh
	mov cx,512	;  cx = num of chars to read
	mov dx,offset buff	;  dx = buffer
	int 21h		;  place chars in buffer

	mov ah,3eh	; file closing
	int 21h		;  close handler in bx

	mov ah,03h	; file writing
	mov al,1	;  al = num of sectors to write
	mov ch,0	;  ch = cyl number
	mov cl,1	;  cl = starting sector num (from 1)
	mov dh,0	;  dh = head number
	mov dl,0	;  dl = device number
	lea bx,buff	;  bx = buffer
	int 13h		;  write buffer to device
	
	ret
buff	db	512 dup(0)
fname	db	"hellwrd.bin",0
end start

; :compile
; tasm /m5 write.bat
; tlink /x/t write.obj
; del write.obj