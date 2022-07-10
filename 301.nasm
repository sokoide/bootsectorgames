; print prime numbers between 2 and 1000
    org 0x0100

table:        equ 0x8000
table_size:    equ 1000

start:
    mov bx, table
    mov cx, table_size
    mov al, 0
p1:
    mov [bx], al
    inc bx
    loop p1                 ; dec cx, jump if non-zero
    mov ax, 2
p2:
    mov bx, table
    add bx, ax
    cmp byte [bx], 0        ; is it prime?
    jne p3
    push ax
    call display_number
    mov al, 0x2c            ; comma
    call display_letter
    pop ax
    mov bx, table
    add bx, ax
p4:
    add bx, ax
    cmp bx, table+table_size
    jnc p3                  ; jmp if not carry (if bx < table+table_size)
    mov byte[bx], 1
    jmp p4
p3:
    inc ax
    cmp ax, table_size
    jne p2


end:
    int 0x20

    %include "library2.nasm"
