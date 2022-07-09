	org 0x0100

board: 		equ 0x0300


start:
	mov bx, board
	mov cx, 9
	mov al, '1'
b09:
	mov [bx], al			; 0x0300: 0x31, 0x32, ..., 0x39
	inc al
	inc bx
	loop b09
b10:
	call show_board
	call get_movement
	mov byte [bx], 'X'

	call show_board

	call get_movement
	mov byte [bx], 'O'

	jmp b10

get_movement:
	call read_keyboard
	cmp al, 0x1b			; ESC?
	je end
	sub al, 0x31			; al = al = '1'
	jc get_movement			; if al < 1
	cmp al, 0x09
	jnc get_movement		; if al > 9
	cbw						;expand AL to 16bit using AH
	mov bx, board
	add bx, ax
	mov al, [bx]
	cmp al, '@'				; numbers should be smaller than '@'. 'X' or 'O' is larger
	jnc get_movement
	call new_line
	ret

end:
	int 0x20

show_board:
	mov bx, board
	call show_row
	call show_div
	mov bx, board+3
	call show_row
	call show_div
	mov bx, board+6
	jmp show_row

show_row:
	call show_square
	mov al, '|'
	call display_letter
	call show_square
	mov al, '|'
	call display_letter
	call show_square
	call new_line
	ret

show_div:
	mov al, '-'
	call display_letter
	mov al, '+'
	call display_letter
	mov al, '-'
	call display_letter
	mov al, '+'
	call display_letter
	mov al, '-'
	call display_letter
	call new_line
	ret

show_square:
	mov al, [bx]
	inc bx
	call display_letter
	ret

	%include "library2.nasm"
