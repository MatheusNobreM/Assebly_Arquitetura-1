; shoot.asm - Versão com contagem até 5
section .data
    count_msg   db "Passo ", 0
    numbers     db "1",10,0,"2",10,0,"3",10,0,"4",10,0,"5",10,0
    msg_draw    db "DRAW! Pressione ENTER agora!", 10, 0
    msg_win     db "Voce foi rapido! Venceu!", 10, 0
    msg_lose    db "Lento demais. Morreu.", 10, 0

section .bss
    buffer resb 1

section .text
    global _start

_start:
    ; --- CONTAGEM DE 1 A 5 ---
    mov rcx, 0                  ; índice inicial
count_loop:
    ; escreve "Passo "
    mov rax, 1
    mov rdi, 1
    mov rsi, count_msg
    mov rdx, 6
    syscall

    ; escreve o número correspondente
    mov rax, 1
    mov rdi, 1
    mov rsi, numbers
    add rsi, rcx                ; pega o número certo
    mov rdx, 3                  ; "n\n\0" = 3 bytes
    syscall

    ; espera 1 segundo (1_000_000 microssegundos)
    mov rax, 35                 ; sys_nanosleep
    mov rdi, timespec_sleep
    xor rsi, rsi                ; NULL
    syscall

    add rcx, 3                  ; vai para o próximo número
    cmp rcx, 15                 ; 5 números → 5 * 3 = 15
    jl count_loop

    ; --- MENSAGEM DRAW ---
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_draw
    mov rdx, 29
    syscall

    ; tempo inicial
    mov rax, 201
    xor rdi, rdi
    syscall
    mov rbx, rax

    ; espera ENTER
    mov rax, 0
    mov rdi, 0
    mov rsi, buffer
    mov rdx, 1
    syscall

    ; tempo final
    mov rax, 201
    xor rdi, rdi
    syscall
    sub rax, rbx

    ; decisão
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
    mov rax, 60
    xor rdi, rdi
    syscall

section .data
timespec_sleep:
    dq 1       ; segundos
    dq 0       ; nanossegundos
