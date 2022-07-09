;
	org 0x0100

start:
	; add
	mov al, 0x04
	add al, 0x03		; al = al + 3
	call print_digit
	call new_line

	; sub
	mov al, 0x04
	sub al, 0x03
	call print_digit
	call new_line

	; mul
	mov al, 0x03
	mov cl, 0x02
	mul cl				; ax = al * cl
	call print_digit
	call new_line

	; div
	mov ax, 0x64
	mov cl, 0x21
	div cl				; ax / cl -> al, remainder -> ah
	push ax
	call print_digit
	call new_line
	pop ax
	mov al, ah
	call print_digit
	call new_line

	; shift
	mov cl, 2
	mov al, 0x02
	shl al, cl
	call print_digit
	call new_line

	; logical operations
	mov al, 0x32
	and al, 0x0f		; AL(0b110010) and 0x0f (0b1111) -> al
	call print_digit
	call new_line

	mov al, 0xfc		; 0b11111100
	not al				; 0b00000011
	call print_digit
	call new_line

	; inc/dec
	mov al, 0
count:
	call print_digit
	inc al
	cmp al, 10
	jne count




end:
	int 0x20

	%include "library1.nasm"
