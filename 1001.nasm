    cpu 8086

    %ifndef com_file
com_file:   equ 1
    %endif

    %if com_file
        org 0x0100
    %else
        org 0x7c00
    %endif

vars:       equ 0x7e00      ; vars, multiple of 256
running:    equ 0x7e7e      ; running status
line:       equ 0x7e80
program:    equ 0x7f00
stack:      equ 0xff00
max_line:  equ 1000        ; max line
max_length: equ 20          ; line max len
max_size:   equ max_line * max_length

        ; program label (line 0)    20 chars (max_length)
        ; +20 (line 1)              20 chars
        ; +40 (line2)               20 chars
        ; ...
        ; +19980 (line 999)         20 chars

start:
    %if com_file
    %else
        push cs
        push cs
        push cs
        pop ds
        pop es
        pop ss
    %endif

    cld
    mov di, program
    mov al, 0x0d
    mov cx, max_size
    rep stosb

        ; main loop
main_loop:
    mov sp, stack
    xor ax, ax
    mov [running], ax       ; mode 0 = interactive mode
    mov al, '>'
    call input_line
    call input_number       ; verify the line starts with a number
    or ax, ax
    je f14
    call find_line
    xchg ax, di
    mov cx, max_length
    rep movsb               ; copy entered line into program
    jmp main_loop

f14:
    call statement
    jmp main_loop

    ; statements
if_statement:
    call expr
    or ax, ax               ; is it zero?
    je f6
statement:
    call spaces
    cmp byte [si], 0x0d     ; empty line?
    je f6
    mov di, statements
f5:
    mov cl, [di]            ; length of the target string
    mov ch, 0
    test cx, cx             ; zero?
    je f4
    push si
    inc di                  ; skip the length byte
f16:
    rep cmpsb               ; compare strings
    jne f3
    pop ax
    call spaces
    jmp word [di]
f3:
    add di, cx
    inc di
    inc di
    pop si
    jmp f5
f4:
    call get_variable
    push ax
    lodsb
    cmp al, '='
    je assignment
error:
    mov si, error_message
    call print_2
    jmp main_loop
error_message:
    db "@#!", 0x0d

list_statement:
    xor ax, ax
f29:
    push ax
    call find_line
    xchg ax, si
    cmp byte [si], 0x0d
    je f30
    pop ax
    push ax
    call output_number      ; show line number
f32:
    lodsb
    call output
    cmp al, 0x0d
    jne f32
f30:
    pop ax
    inc ax                  ; goto next line
    cmp ax, max_line
    jne f29
f6:
    ret

input_statement:
    call get_variable
    push ax
    mov al, '?'
    call input_line

assignment:
    call expr
    pop di
    stosw
    ret

expr:
    call expr1
f20:
    cmp byte [si], '-'
    je f19
    cmp byte [si], '+'
    jne f6
    push ax
    call expr1_2
    pop cx
    add ax, cx
    jmp f20
f19:
    push ax
    call expr1_2
    pop cx
    xchg ax, cx
    sub ax, cx
    jmp f20

expr1_2:
    inc si                  ; skip operator
expr1:
    call expr2
f21:
    cmp byte [si], '/'
    je f23
    cmp byte [si], '*'
    jne f6
    push ax
    call expr2_2
    pop cx
    imul cx
    jmp f21
f23:
    push ax
    call expr2_2
    pop cx
    xchg ax, cx
    cwd
    idiv cx
    jmp f21
expr2_2:
    inc si
expr2:
    call spaces
    lodsb
    cmp al, '('
    jne f24
    call expr
    cmp byte [si], ')'
    jne error
    jmp spaces_2
f24:
    cmp al, 0x40            ; variable?
    jnc f25
    dec si
    call input_number
    jmp spaces
f25:
    call get_variable_2
    xchg ax, bx
    mov ax, [bx]
    ret
get_variable:
    lodsb
get_variable_2:
    and al, 0x1f            ; 0x61-0x7a -> 0x01-0x1a
    add al, al              ; x2
    mov ah, vars>>8
spaces:
    ; skip spaces
    cmp byte [si], ' '
    jne f22
spaces_2:
    inc si
    jmp spaces
output_number:
f26:
    xor dx, dx
    mov cx, 10
    div cx
    or ax, ax
    push dx
    je f8
    call f26
f8:
    pop ax
    add al, '0'
    jmp output
input_number:
    xor bx, bx
f11:
    lodsb
    sub al, '0'
    cmp al, 10
    cbw
    xchg ax, bx
    jnc f12
    mov cx, 10
    mul cx
    add bx, ax
    jmp f11
f12:
    dec si
f22:
    ret
run_statement:
    xor ax, ax
    jmp f10
goto_statement:
    call expr
f10:
    call find_line
f27:
    cmp word [running], 0
    je f31
    mov [running], ax
    ret
f31:
    push ax
    pop si
    add ax, max_length
    mov [running], ax
    call statement
    mov ax, [running]
    cmp ax, program+max_size
    jne f31
    ret

find_line:
    ; find line in program
    ; args) ax = line number
    ; ret) ax = pointer to program
    mov cx, max_length
    mul cx
    add ax, program
    ret
input_line:
    call output
    mov si, line
    push si
    pop di
f1:
    call input_key
    cmp al, 0x08
    jne f2
    dec di
    jmp f1
f2:
    stosb
    cmp al, 0x0d
    jne f1
    ret
print_statement:
    lodsb
    cmp al, 0x0d
    je new_line
    cmp al, '"'
    jne f7
print_2:
f9:
    lodsb
    cmp al, '"'
    je f18
    call output
    cmp al, 0x0d
    jne f9
    ret
f7:
    dec si
    call expr
    call output_number
f18:
    lodsb
    cmp al, ';'
    jne new_line
    ret
input_key:
    mov ah, 0x00
    int 0x16
output:
    cmp al, 0x0d
    jne f17
new_line:
    mov al, 0x0a
    call f17
    mov al, 0x0d
f17:
    mov ah, 0x0e
    int 0x10
    ret
statements:
    db 3, "new"
    dw start

    db 4, "list"
    dw list_statement

    db 3, "run"
    dw run_statement

    db 5, "print"
    dw print_statement

    db 5, "input"
    dw input_statement

    db 2, "if"
    dw if_statement

    db 4, "goto"
    dw goto_statement

    %if com_file
        db 6, "system"
        dw 0
    %endif
    db 0

    ; boot sector filler
    %if com_file
    %else
        times 510-($-$$) db 0x4f
        db 0x55, 0xaa
    %endif
