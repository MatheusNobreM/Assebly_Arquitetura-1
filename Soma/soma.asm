section .data
    result db 0    ; Armazena o caractere do resultado

section .text
    global _start

_start:
    mov eax, 5  
    add eax, 3      

    ; Converter o resultado para caractere ASCII
    add eax, '0'    ; Converte o número em EAX (8) para caractere ASCII ('8')
    mov [result], al ; Armazena o caractere no buffer result

    ; Imprimir o resultado
    mov eax, 4      ; Chamada de sistema para write
    mov ebx, 1      ; Descritor de arquivo 1 (stdout)
    mov ecx, result ; Endereço do buffer (result)
    mov edx, 1      ; Comprimento da string (1 byte)
    int 0x80        

    
    mov eax, 1      ; Chamada de sistema para exit
    mov ebx, 0      ; Código de saída 0
    int 0x80        