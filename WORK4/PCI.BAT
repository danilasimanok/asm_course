; @echo off
; goto compile

.model tiny
.code
.486

org 100h

_:
	lea dx,tabhd	; print table header
	mov ah,09h	;  .
	int 21h		;  .

	; to get info from PCI we need to send
	;  | 100000000 | busn | devn | funn | offset | to 0cf8h
	;
	;  field    || busn | devn | funn | offset |
	;  -----------------------------------------
	;  len(bit) ||  8   |  5   |  3   |  8     |
	;
	;  device_id and vendor_id are placed by offset = 0
	; the answer will return in 0cfch

	xor cx,cx	; cx = 0 // cx will be used for cycle

lp1:	mov ax,cx	; set up busn, devn, funn in eax
	shl eax,8	;  .

	mov dx,0cf8h	; eax = info from PCI
	out dx,eax	;  . // used dx since constatnt too large
	mov dx,0cfch	;  .
	in eax,dx	;  .

	cmp eax,0ffffffffh	; if error occured then skip printing
	je error	;  .

	mov ebx,eax	; write vendor_id (it is in last 16 bit (bx))
	lea di,vendid	;  .
	call h4		;  .

	ror ebx,16	; write device_id (16 bit in exb rotated)
	lea di,devid	;  .
	call h4		;  .

	mov bl,ch	; write bus
	lea di,bus	;  .
	call h2		;  .

	mov bl,cl	; write device
	shr bl,3	;  .
	lea di,device	;  .
	call h2		;  .

	mov bl,cl	; write func
	and bl,00000111b	; .
	lea di,func	;  .
	call h2		;  .

	mov ah,09h	; print buf
	lea dx,buf	;  .
	int 21h		;  .

error:	inc cx		; cx += 1

	cmp cx,0ffffh	; repeat until cx = ffff
	jb lp1		;  .

	ret

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

tabhd	db	"bus : device : function : vendor_id : device_id",13,10,"$"
buf:
bus	db	"__ : "
device	db	"__ : "
func	db	"__ : "
vendid	db	"____ : "
devid	db	"____",13,10,"$"

end _

; :compile
; tasm /m5 pci.bat
; tlink /x/t pci.obj
; del pci.obj