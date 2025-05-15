GLOBAL _start

CR equ 13
LF equ 10

section .data
    a dd 15; 4bytes
    b dd 42; 4bytes
    msg db "Maior";
    msglen equ $ - msg;

section .bss
    num_str: resb 16;

section .text
_start:
    ;Carregar os valores de a e b
    mov eax, [a];
    mov ebx, [b];
    ;Comparar os valores
    ;Se a for maior que b, imprimir a
    cmp eax, ebx;
    jl b_maior
    call show_result
    jmp fim

    ;ebx maior
b_maior:
    mov eax, ebx;
    call show_result
    jmp fim

show_result:
    ;Converter o número para string
    mov ecx, 10
    xor edx, edx ; zerar para dividendo alto
    div ecx         ; resto(edx):quociente(eax)/ecx -> quociente em eax, resto em edx
    add eax, 0x30; dezena
    add edx, 0x30; unidade

    mov ecx , num_str
    mov [ecx], al
    mov [ecx+1], dl
    mov byte [ecx+2], LF

    ; escrever "Maior: "
    mov eax, 4
    mov ebx, 1
    mov ecx, msg
    mov edx, msglen
    int 0x80

    ; escrever o número
    mov eax, 4
    mov ebx, 1
    mov ecx, num_str
    mov edx, 3      ; 2 dígitos + newline
    int 0x80
    ret

fim:
    ;Escrever o resultado
    mov eax, 1
    xor ebx, ebx
    int 0x80