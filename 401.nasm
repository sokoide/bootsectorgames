    org 0x0100

    mov ax, 0x0002          ; 80x25, 16 color mode
    int 0x10

    mov ax, 0xb800
    mov ds, ax
    mov es, ax

    cld                     ; clear DI/SI direction
    xor di, di
    mov ax, 0x1a48          ; H, bg: blue
    stosw                   ; store ax in [DI], DI+=2
    mov ax, 0x1b45          ; E
    stosw
    mov ax, 0x1c4c          ; L
    stosw
    mov ax, 0x1d4c          ; L
    stosw
    mov ax, 0x1e4f          ; O
    stosw
    int 0x20
