; hello world
    org 0x100

start:
    mov ax, 0x0003          ; text mode 80x25, 16colors, 8pages
    int 0x10
    mov bx, string

repeat:
    mov al, [bx]
    test al, al             ; test if al is zero
    jz end
    push bx
    mov ah, 0x0e            ; AX=0x0e -> AL=character, BH=page, BL=color
    mov bx, 0x000f          ; BH=page 0, BL=0xf (color white)
    int 0x10
    pop bx
    inc bx
    jmp repeat

end:
    int 0x20

string:
    db "Hello, world!", 0
