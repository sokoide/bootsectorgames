    ; VGA palette

    cpu 8086
    org 0x0100

    ; 320x200 = 64,000 byte VRAM is used from 0x0000
    ; 0xfa00 is the first VRAM byte which is invisible
v_a:    equ 0xfa00
v_b:    equ 0xfa02

start:
    mov ax, 0x0013              ; 320x200, 256color
    int 0x10

    mov ax, 0xa000              ; 0xa000 vram segment
    mov ds, ax
    mov es, ax

    cld                         ; clear DI/SI direction

m4:
    mov ax, 127                 ; row 127
    mov [v_a], ax
m0:
    mov ax, 127
    mov [v_b], ax               ; column 127

m1:
    mov ax, [v_a]
    mov dx, 320
    mul dx                      ; row AX = AX * 320
    add ax, [v_b]               ; +column
    xchg ax, di                 ; DI <- AX (smaller than mov di, ax)

    mov ax, [v_a]               ; current Y
    ; AX = int(Y/8)*16
    and ax, 0x78                ; 0b_0111_1000
    shl ax, 1                   ; y=0-7 -> AX=0, y=9-15 -> AX=0x10, ..., y=127 -> AX=0xf0

    mov bx, [v_b]
    and bx, 0x78
    mov cl, 3
    shr bx, cl                  ; BX = BX / 8 (BX becomes 0-15)
    add ax, bx
    stosb                       ; plot AL in DI

    dec word [v_b]
    jns m1

    dec word [v_a]
    jns m0

    mov ah, 0x00
    int 0x16                    ; wait for key

    mov ax, 0x0002
    int 0x10


end:
    int 0x20
