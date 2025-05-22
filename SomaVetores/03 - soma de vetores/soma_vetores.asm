tamanho equ 10

section .data
    vetor1      dd 1,2,3,4,5,6,7,8,9,10
    vetor2      dd 10,20,30,40,50,60,70,80,90,100
    
section .bss
    resultado   resd 10

section .text
    extern print_array_int
    global main

main:
    ; --- soma dois vetores ---
    mov rdi, vetor1
    mov rsi, vetor2
    mov rdx, resultado
    mov rcx, tamanho
    call soma_array
    
    ; --- exibe os resultados usando uma funcao em C---
    mov rdi, resultado           ; 1º argumento: ponteiro para vetor
    mov rsi, tamanho             ; 2º argumento: tamanho do vetor
    call print_array_int
    
    jmp fim
    
; void soma_array(int *vetor1, int* vetor2, int* resultado, int tamanho)        
soma_array:

    mov rax, [rsi]
    add rax, [rdi]
    mov [rdx], rax

    add rsi, 8
    add rdi, 8
    add rdx, 8

    loop soma_array
    
    ret
    
fim:
    mov rax, 1
    xor rbx, rbx
    int 0x80
    
    



    
