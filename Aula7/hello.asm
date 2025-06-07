section .data
    msg db "Boa noite.", 10
    tamB equ $-msg
section .text
    global _start
_start:
    ;imprindo a msg
    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, tamB
    syscall

    ;encerrando o programa
    mov rax, 60
    mov rdi, 0
    syscall 