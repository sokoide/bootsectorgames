    org 0x0100

    mov ax, 0x0002          ; 80x25, 16 color mode
    int 0x10

    mov ax, 0xb800
    mov ds, ax
    mov es, ax

    cld                     ; clear DI/SI direction

main_loop:
    mov ah, 0x00
    int 0x1a                ; read clock
    mov al, dl
    test al, 0x40           ; bit 6 is 1?
    je m2
    not al
m2:
    and al, 0x3f            ; separate lower 6 bits
    sub al, 0x20            ; make it -32 to 31
    cbw                     ; extend AL to AX
    mov cx, ax

    mov di, 0x0000
    mov dh, 0               ; row
m0:
    mov dl, 0               ; column
m1:
    push dx
    mov bx, sin_table

    mov al, dh              ; take the row
    shl al, 1               ; 2x because of aspect ratio
    and al, 0x3f            ; Make it 0-63
    cs xlat                 ; extract sin value (mov al, [bx+al])
    cbw
    push ax

    mov al, dl              ; take the column
    and al, 0x3f            ; Mkae it 0-63
    cs xlat
    cbw
    pop dx
    add ax, dx
    add ax, cx
    mov ah, al
    mov al, '*'
    mov [di], ax
    add di, 2

    pop dx
    inc dl
    cmp dl, 80
    jne m1

    inc dh
    cmp dh, 25
    jne m0

    mov ah, 0x01
    int 0x16
    jne key_pressed
    jmp main_loop

key_pressed:
    int 0x20

sin_table:
    db 0, 6, 12, 19, 24, 30, 36, 41
    db 45, 49, 53, 56, 59, 61, 63, 64
    db 64, 64, 63, 61, 59, 56, 53, 49
    db 45, 41, 36, 30, 24, 19, 12, 6
    db 0, -6, -12, -19, -24, -30, -36, -41
    db -45, -49, -53, -56, -59, -61, -63, -64
    db -64, -64, -63, -61, -59, -56, -53, -49
    db -45, -41, -36, -30, -24, -19, -12, -6
