tamanho equ 10

section .data
    vetor   dd 10, 2, 9, 4, 7, 1, 6, 5, 8, 3   ; vetor a ser ordenado

section .text
    extern print_array_int
    global main

main:
    ; --- ordena vetor com bubble sort ---
    mov rdi, vetor
    mov rsi, tamanho
    call bubble_sort

    ; --- imprime vetor ordenado ---
    mov rdi, vetor
    mov rsi, tamanho
    call print_array_int

    ; fim do programa (exit)
    mov rax, 60         ; syscall: exit
    xor rdi, rdi        ; status 0
    syscall

; void bubble_sort(int* vetor, int tamanho)
bubble_sort:
    push rbp
    mov rbp, rsp

    ; rdi = ponteiro para vetor
    ; rsi = tamanho

    mov r8, rsi         ; contador externo: n
    dec r8              ; r8 = n - 1

.loop_externo:
    mov r9, 0           ; índice interno (i)

.loop_interno:
    mov eax, [rdi + r9*4]       ; eax = vetor[i]
    mov ebx, [rdi + r9*4 + 4]   ; ebx = vetor[i+1]

    cmp eax, ebx
    jle .nao_trocar

    ; troca vetor[i] e vetor[i+1]
    mov [rdi + r9*4], ebx
    mov [rdi + r9*4 + 4], eax

.nao_trocar:
    inc r9
    cmp r9, r8
    jl .loop_interno

    dec r8
    cmp r8, 0
    jg .loop_externo

    pop rbp
    ret
