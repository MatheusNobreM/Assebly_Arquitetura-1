; COWBOY SHOOTOUT - Jogo em NASM 64 bits (Linux)
; Compilar: nasm -f elf64 cowboy64.asm -o cowboy64.o && ld cowboy64.o -o cowboy64

%define SYS_READ       0
%define SYS_WRITE      1
%define SYS_EXIT       60
%define SYS_NANOSLEEP  35
%define SYS_IOCTL      16
%define SYS_FCNTL      72
%define SYS_TIME       201
%define SYS_SIGACTION  13
%define SYS_POLL       7

%define STDIN          0
%define STDOUT         1

%define ICANON         2
%define ECHO           8
%define TCSANOW        0
%define O_NONBLOCK     04000
%define SIGINT         2
%define SA_RESTORER    0x04000000
%define POLLIN         0x001

section .data
    intro_msg     db "COWBOY SHOOTOUT -",10,"YOU ARE BACK TO BACK",10,"TAKE 10 PACES...",10,10,0
    early_msg     db 10,"YOU DREW TOO EARLY!",10,"YOU ARE DEAD.",10,10,0
    draw_msg      db 10,"HE DRAWS...",10,0
    win_msg       db "BUT YOU SHOOT FIRST.",10,"YOU KILLED HIM.",10,10,0
    lose_msg      db "AND SHOOTS...",10,"YOU ARE DEAD.",10,10,0
    exit_msg      db "Press any key to exit.",10,10,0
    space_hint    db "Press SPACE to shoot!",10,0
    number_10_str db "10",10

section .bss
    key          resb 1
    step_buf     resb 2
    tspec        resq 2
    old_termios  resb 48
    new_termios  resb 48
    sig_action   resb 152
    pollfd       resb 8

section .text
global _start

; =====================
; Handler para SIGINT
; =====================
sigint_handler:
    call restore_terminal
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; =====================
; Programa principal
; =====================
_start:
    ; === Instalar handler SIGINT ===
    mov qword [sig_action], sigint_handler     ; sa_handler
    mov qword [sig_action + 8], 0             ; sa_flags
    mov qword [sig_action + 16], SA_RESTORER  ; sa_restorer
    mov qword [sig_action + 24], 0            ; sa_mask

    mov rax, SYS_SIGACTION
    mov rdi, SIGINT
    lea rsi, [sig_action]
    xor rdx, rdx
    mov r10, 8
    syscall

    call set_raw_mode

    ; Exibir introdução
    mov rdi, intro_msg
    call print_string

    mov r12, 1
.count_loop:
    cmp r12, 10
    jne .print_step
    
    ; Imprimir "10"
    mov rdi, number_10_str
    call print_string
    jmp .newline

.print_step:
    mov rax, r12
    add al, '0'
    mov [step_buf], al
    mov byte [step_buf+1], 10
    
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, step_buf
    mov rdx, 2
    syscall

.newline:
    call flush_keyboard
    call sleep_1s
    call check_keypress
    cmp rax, 1
    je drew_early
    
    inc r12
    cmp r12, 11
    jne .count_loop

    ; Exibir dica
    mov rdi, space_hint
    call print_string

    call flush_keyboard
    call get_random_delay
    call wait_draw_or_key
    cmp rax, 1
    je win

    mov rdi, draw_msg
    call print_string

    call wait_2s_or_key
    cmp rax, 1
    je win

lose:
    mov rdi, lose_msg
    call print_string
    jmp end_game

win:
    mov rdi, win_msg
    call print_string
    jmp end_game

drew_early:
    mov rdi, early_msg
    call print_string
    jmp end_game

end_game:
    mov rdi, exit_msg
    call print_string

    call wait_key
    call restore_terminal

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; =====================
; Funções auxiliares
; =====================

print_string:
    push rsi
    push rdx
    push rax
    push rdi
    
    ; Calcular tamanho da string
    xor rcx, rcx
    mov rsi, rdi
.count_loop:
    lodsb
    test al, al
    jz .count_done
    inc rcx
    jmp .count_loop
.count_done:
    
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    pop rsi
    mov rdx, rcx
    syscall
    
    pop rax
    pop rdx
    pop rsi
    ret

wait_key:
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, key
    mov rdx, 1
    syscall
    ret

check_keypress:
    ; Configurar pollfd
    mov dword [pollfd], STDIN
    mov dword [pollfd + 4], POLLIN
    
    mov rax, SYS_POLL
    mov rdi, pollfd
    mov rsi, 1
    mov rdx, 0
    syscall
    
    test rax, rax
    jz .nokey
    
    ; Tem tecla pressionada - ler
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, key
    mov rdx, 1
    syscall
    
    cmp rax, 1
    jne .nokey
    mov rax, 1
    ret
.nokey:
    xor rax, rax
    ret

flush_keyboard:
.flush:
    call check_keypress
    cmp rax, 1
    je .flush
    ret

sleep_1s:
    mov qword [tspec], 1
    mov qword [tspec+8], 0
    mov rax, SYS_NANOSLEEP
    mov rdi, tspec
    xor rsi, rsi
    syscall
    ret

get_random_delay:
    mov rax, SYS_TIME
    xor rdi, rdi
    syscall
    
    ; Usar AL para gerar número entre 2-4
    and eax, 0x3  ; 0-3
    add eax, 2     ; 2-5
    cmp eax, 4
    jle .ok
    mov eax, 4
.ok:
    mov r13d, eax  ; Salvar em R13
    ret

wait_draw_or_key:
    ; R13 contém o delay (2-4)
    imul r13, 10   ; Converter para décimos de segundo
    
.loop:
    call check_keypress
    cmp rax, 1
    je .reacted
    
    ; Esperar 0.1 segundo
    mov qword [tspec], 0
    mov qword [tspec+8], 100000000  ; 100ms
    
    mov rax, SYS_NANOSLEEP
    mov rdi, tspec
    xor rsi, rsi
    syscall
    
    dec r13
    jnz .loop
    
    xor rax, rax
    ret
.reacted:
    mov rax, 1
    ret

wait_2s_or_key:
    mov r14, 20  ; 20 x 0.1s = 2s
    
.loop:
    call check_keypress
    cmp rax, 1
    je .pressed
    
    ; Esperar 0.1 segundo
    mov qword [tspec], 0
    mov qword [tspec+8], 100000000  ; 100ms
    
    mov rax, SYS_NANOSLEEP
    mov rdi, tspec
    xor rsi, rsi
    syscall
    
    dec r14
    jnz .loop
    
    xor rax, rax
    ret
.pressed:
    mov rax, 1
    ret

set_raw_mode:
    ; Obter configurações atuais
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, 0x5401  ; TCGETS
    mov rdx, old_termios
    syscall
    
    ; Copiar para new_termios
    mov rsi, old_termios
    mov rdi, new_termios
    mov rcx, 48
    rep movsb
    
    ; Desativar ECHO e ICANON
    mov rdi, new_termios
    and dword [rdi + 12], ~(ECHO | ICANON)
    
    ; Aplicar novas configurações
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, 0x5402  ; TCSETS
    mov rdx, new_termios
    syscall
    
    ; Configurar modo não-bloqueante
    mov rax, SYS_FCNTL
    mov rdi, STDIN
    mov rsi, 3  ; F_GETFL
    syscall
    
    mov rdi, STDIN
    mov rsi, 4  ; F_SETFL
    mov rdx, rax
    or rdx, O_NONBLOCK
    syscall
    
    ret

restore_terminal:
    ; Restaurar configurações antigas
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, 0x5402  ; TCSETS
    mov rdx, old_termios
    syscall
    
    ; Restaurar flags de arquivo
    mov rax, SYS_FCNTL
    mov rdi, STDIN
    mov rsi, 3  ; F_GETFL
    syscall
    
    mov rdi, STDIN
    mov rsi, 4  ; F_SETFL
    mov rdx, rax
    and rdx, ~O_NONBLOCK
    syscall
    
    ret