section .data
    pergunta  db "Como voce se chama", 10
    tamPerg equ $-pergunta

    ola db "Ola, "
    tamOla equ $-ola
    tamNome equ 10

section .bss
    nome resb tamNome

section .text
    global _start

_start:
    ;imprimindo a mensagem 'Como voce se chama'
    mov rax, 1
    mov rdi, 1
    mov rsi, pergunta
    mov rdx, tamPerg
    syscall

    ;ler o nome do usário
    mov rax, 0
    mov rdi, 0
    mov rsi, nome
    mov rdx, tamNome
    syscall

    ;imprimindo mensagem 'Ola, '
    mov rax, 1 
    mov rdi, 1
    mov rsi, ola
    mov rdx, tamOla
    syscall

    ;imprimindo o nome do usuário
    mov rax, 1
    mov rdi, 1
    mov rsi, nome
    mov rdx, tamNome
    syscall

    ;encerrando o programa
    mov rax, 60
    mov rdi, 0
    syscall
