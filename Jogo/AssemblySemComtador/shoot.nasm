; shoot.asm - Versão simplificada
section .data
    msg_draw        db "DRAW! Pressione ENTER agora!", 10, 0
    msg_win         db "Voce foi rapido! Venceu!", 10, 0
    msg_lose        db "Lento demais. Morreu.", 10, 0
    newline         db 10, 0

section .bss
    buffer resb 1

section .text
    global _start

_start:
    ; Imprime "DRAW!"
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, msg_draw
    mov rdx, 29         ; tamanho da string
    syscall

    ; Get start time
    mov rax, 201        ; sys_time
    xor rdi, rdi        ; NULL
    syscall
    mov rbx, rax        ; tempo inicial

    ; Espera ENTER (1 byte)
    mov rax, 0          ; sys_read
    mov rdi, 0          ; stdin
    mov rsi, buffer
    mov rdx, 1
    syscall

    ; Get end time
    mov rax, 201        ; sys_time
    xor rdi, rdi
    syscall

    sub rax, rbx        ; tempo de reação em segundos

    ; Se rax < 2, vence. Caso contrário, perde.
    cmp rax, 2
    jl venceu

morreu:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_lose
    mov rdx, 25
    syscall
    jmp sair

venceu:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_win
    mov rdx, 27
    syscall

sair:
    mov rax, 60         ; sys_exit
    xor rdi, rdi
    syscall
