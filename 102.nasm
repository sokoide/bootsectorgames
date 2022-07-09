; keyboar input
	org 0x100

start:
	mov ah, 0x00		; keyboard read
	int 0x16			; call bios

	cmp al, 0x1b		; ESC pressed?
	je end
	mov ah, 0x0e		; terminal output
	mov bx, 0x000f
	int 0x10
	jmp start

end:
	int 0x20
