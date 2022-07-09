	int 0x20		; exit to command line

display_letter:
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	mov ah, 0x0e
	mov bx, 0x000f
	int 0x10
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret

display_number:
	mov dx, 0
	mov cx, 10
	div cx		; ax = dx:ax / cx, remainder in dx
	push dx
	cmp ax, 0
	je display_number_1
	call display_number
display_number_1:
	pop ax
	add al, '0'
	call display_letter
	ret


read_keyboard:
	push bx
	push cx
	push dx
	push si
	push di
	mov ah, 0x00		; load AH with code for keyboard read
	int 0x16			; keyboard read
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	ret

new_line:
	push ax
	mov al, 0x0a
	call display_letter
	mov al, 0x0d
	call display_letter
	pop ax
	ret

change_display_mode:
	mov ax, 0x0003
	int 0x10
	ret
