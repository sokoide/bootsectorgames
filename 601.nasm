    use16
    cpu 8086
    org 0x0100

pipe:    equ 0x0fa0
score:    equ 0x0fa2
grav:    equ 0x0fa4
next:    equ 0x0fa6
bird:    equ 0x0fa8
tail:    equ 0x0faa
frame:    equ 0x0fac

    mov ax, 0x0002              ; 80x25 text mode
    int 0x10
    cld                         ; reset direction flag
    mov ax, 0xb800              ; vram
    mov ds, ax
    mov es, ax

; game
fb21:
    ; F - Bird
    mov di, pipe
    xor ax, ax
    stosw                       ; pipe
    stosw                       ; score
    stosw                       ; grav
    mov al, 0xa0
    stosw                       ; next
    mov al, 0x60
    stosw                       ; bird

    mov di, 0x004a              ; game title
    mov ax, 0x0f46              ; F in white
    stosw
    mov al, '-'
    stosw
    mov al, 'B'
    stosw
    mov al, 'I'
    stosw
    mov al, 'R'
    stosw
    mov al, 'D'
    stosw

    mov cx, 80                  ; 80 column scene
fb1:
    push cx
    call scroll_scenery
    pop cx
    loop fb1

fb23:
    ; empty keyboard buffer and wait for key input
    mov ah, 0x01
    int 0x16
    pushf
    xor ax, ax
    int 0x16
    popf
    jnz fb23

; main loop
fb12:
    mov al, [bird]
    add al, [grav]
    mov [bird], al

    and al, 0xf8                ; 0xf8=0b1111_1000. row is a 5.3 fraction. nullify fraction
    mov ah, 0x14
    ; to calculate the address of text vram row,
    ; vram row = 80 (chars) * 2 (attrs) * y = 160 * y
    ; AL is y * 8 (since 5.3 fraction)
    ; so, we'll make it *20
    mul ah                      ; AL = AL * AH(20)
    add ax, $0020               ; add 32 cells to the right
    xchg ax, di

    mov al, [frame]
    and al, 4                   ; wing movement each 4 frames
    jz fb15

    ; hit test
    mov al, [di-160]            ; get BG character at (X, Y-1)
    mov word [di-160], 0x0d1e   ; draw upper wing
    add al, [di]                ; add another character at (X, Y)
    shr al, 1                   ; average it. (Space 0x20 + space 0x20) / 2 == 0x20 is expected if it's not crashed
    mov word [di], 0x0d14       ; draw body
    jmp short fb16
fb15:
    mov al, [di]                ; get a BG charater at (X, Y)
    mov word [di], 0x0d1f       ; draw body
fb16:
    add al, [di+2]              ; add another BG character at (X+1, Y)
    mov word [di+2], 0x0d10     ; draw head
    cmp al, 0x40                ; collision test. if it's 2 spaces (0x20 +0x20), not crashed
    jz fb19

; stars and game over
    mov byte [di], '*'          ;'*' to indicate crashing
    mov byte [di+2], '*'
    mov di, 0x07ca
    mov ax, 0x0f42              ; B
    stosw
    mov al, 'O'
    stosw
    mov al, 'N'
    stosw
    mov al, 'K'
    stosw
    mov al, '!'
    stosw
    mov cx, 100
fb20:
    push cx
    call wait_frame
    pop cx
    loop fb20
    jmp fb21                    ; restart
fb19:
    ; per frame
    call wait_frame
    mov al, [frame]
    test al, 7
    jnz fb17
    inc word [grav]             ; increase grav every 8 frames
fb17:
    ; clear bird
    mov al, $20                 ; space (blank) char
    mov [di-160], al            ; clear bird char at (X, Y-1)
    mov [di+2], al              ; clear bird char at (X+1, Y)
    stosb                       ; clear bird char at (X, Y)
    call scroll_scenery
    call scroll_scenery
    ; hit test with pipe for scoring
    cmp byte [0x00a0], 0xb0     ; check if 0xa0 160 (0, 1) is 0xb0 (pipe)
    jz fb27
    cmp byte [0x00a2], 0xb0     ; check if 0xa1 162 (1, 1) is 0xb0. this is because scroll_scenery is called twice per cycle
fb27:
    ; increment and show score
    jnz fb24
    inc word [score]            ; increment score
    mov ax, [score]
    mov di, 0x008e              ; 8e==142 -> (71, 0)
fb25:
    xor dx, dx                  ; extend AX to 32bit DX:AX
    mov bx, 10
    div bx                      ; AX = (DX:AX) / BX, DX = remainder
    add dx, 0x0c30              ; color 0x0c, char->ASCII 1st digit score by adding 0x30
    xchg ax, dx                 ; swap AX and DX. AX=score+color, DX=quotient
    std                         ; set direction (di will be decremented)
    stosw                       ; write AX (1st digit score)
    mov byte [di], 0x20         ; clear a char on the left of the char
    cld                         ; clear direction
    xchg ax, dx                 ; swap AX and DX. AX=quotient
    or ax, ax
    jnz fb25                    ; if quotient != 0, repeat
fb24:
    mov ah, 0x01
    int  0x16                   ; key buffer check
    jz fb26                     ; if nothing is in buffer
    mov ah, 0x00
    int 0x16                    ; read key
    cmp al, 0x1b                ; ESC key?
    jne fb4
    int 0x020
fb4:
    ; bird jump
    mov ax, [bird]
    sub ax, 0x10                ; 0x10=0b_10_000 -> since it's 5.3 fraction, it's integer 2
    cmp ax, 0x08                ; 0x08=0b_1_000 if Y < 1, don't change bird's Y
    jb fb18
    mov [bird], ax
fb18:
    mov byte [grav], 0
    mov al, 0xb6                ; flap sound
    out (0x43), al
    mov al,0x90
    out (0x42), al
    mov al, 0x4a
    out (0x42), al
    in al, (0x61)
    or al, 0x03                 ; turn on sound
    out (0x61), al
fb26:
    jmp fb12                    ; jump to main loop
scroll_scenery:
    mov si, 0x00a2              ; 162. row 1, column 1
    mov di, 0x00a0              ; 160. row 1, column 0
fb2:
    mov cx, 79                  ; move 79 columns
    repz                        ; repeat until CX != 0
    movsw
    mov ax, 0x0e20              ; delete the right most column
    stosw
    lodsw                       ; advance SI
    cmp si, 0x0fa2              ; last cell?
    jnz fb2
    ; insert houses
    mov word [0x0f9e], 0x02df   ; green ground
    in al, (0x40)               ; get random number
    and al, 0x70
    jz fb5
    mov bx, 0x0408              ; building 1st floor
    mov [0x0efe], bx
    mov di, 0x0e5e
    and al, 0x20
    jz fb3
    mov [di], bx                ; building 2nd floor
    sub di, 0x00a0
fb3:
    mov word [di], 0x091e       ; add roof
fb5:
    ; check if it's time to insert a pipe
    dec word [next]
    mov bx, [next]
    cmp bx, 0x03
    ja fb6
    jne fb8
    in al, (0x40)
    and ax, 0x0007
    add al, 0x04
    mov [tail], ax
fb8:
    mov cx, [tail]
    or bx, bx
    mov dl, 0xb0
    jz fb7
    mov dl, 0xdb
    cmp bx, 0x03
    jb fb7
    mov dl, 0xb1
fb7:
    mov di, 0x013e
    mov ah, 0x0a
    mov al, dl
fb9:
    stosw
    add di, 0x009e
    loop fb9
    mov al, 0xc4
    stosw
    add di, 0x009e*6+10
    mov al, 0xdf
    stosw
    add di, 0x009e
fb10:
    mov al, dl
    stosw
    add di, 0x009e
    cmp di, 0x0f00
    jb fb10
    or bx, bx
    jnz fb6
    mov ax, [pipe]
    inc ax
    mov [pipe], ax
    mov cl, 3
    shr ax, cl
    mov ah, 0x50
    sub ah, al
    cmp ah, 0x10
    ja fb11
    mov ah, 0x10
fb11:
    mov [next], ah
fb6:
    ret
wait_frame:                     ; 18.2hz
    mov ah, 0x00
    int 0x1a                    ; get system clock (18.2hz) in CX:DX
fb14:
    push dx                     ; save DX (clock)
    mov ah, 0x00
    int 0x1a                    ; get system clock again
    pop bx
    cmp bx, dx                  ; compare until it changes
    jz fb14
    inc word [frame]            ; increase frame
    in al, (0x61)
    and al, 0xfc                ; turn off sound
    out (0x61), al
    ret
end:
    int 0x20
