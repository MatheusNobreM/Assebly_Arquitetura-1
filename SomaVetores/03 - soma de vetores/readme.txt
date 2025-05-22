----------------------------------------------
Tamanhos das variáveis na seção data
----------------------------------------------
| Diretiva | Tamanho por unidade | Exemplo                               |
| -------- | ------------------- | ------------------------------------- |
| db       | 1 byte              | db 65 ou db 'A'                       |
| dw       | 2 bytes             | dw 0x1234                             |
| dd       | 4 bytes             | dd 10, 20, 30                         |
| dq       | 8 bytes             | dq 0x1122334455667788                 |
| dt       | 10 bytes            | dt 1.2345e20 (FPU extended)           |
| do       | 16 bytes            | do 0x123456789ABCDEF0123456789ABCDEF0 |

----------------------------------------------
Tamanhos das variáveis na seção bss
----------------------------------------------
| Diretiva | Tamanho por unidade | Exemplo   | Significado                                       |
| -------- | ------------------- | --------- | ------------------------------------------------- |
| resb     | 1 byte              | resb 10   | Reserva 10 bytes                                  |
| resw     | 2 bytes             | resw 4    | Reserva 4 * 2 = 8 bytes                           |
| resd     | 4 bytes             | resd 3    | Reserva 3 * 4 = 12 bytes                          |
| resq     | 8 bytes             | resq 2    | Reserva 2 * 8 = 16 bytes                          |
| rest     | 10 bytes            | rest 1    | Reserva 1 * 10 = 10 bytes (formato FPU estendido) |
| reso     | 16 bytes            | reso 1    | Reserva 1 * 16 = 16 bytes (ex.: vetor 128 bits)   |



----------------------------------------------    
 Ordem dos argumentos para chamadas de função:
----------------------------------------------
Em sistemas de 64 bits:
 os 6 primeiros argumentos vão em: RDI, RSI, RDX, RCX, R8, R9, respectivamente
 os demais argumentos vão na pilha (iniciando do último)
   
Em sistemas de 32 bits:
 os argumentos são passado na pilha (iniciando do último)

-----------------------------------------------
 Retorno de valores   
-----------------------------------------------
Em sistemas de 64 bits:

Se a função retorna um inteiro ou ponteiro, o valor vem no registrador rax.
Se retorna um float ou double, o valor vem no registrador xmm0.
Se retorna uma struct pequena (até 16 bytes), o valor é colocado em rax (e rdx, se necessário).
Se retorna uma struct grande, você precisa passar um ponteiro como argumento para onde a função deve escrever o resultado.

Em sistemas de 32 bits:

Se a função retorna um inteiro ou ponteiro, o valor vem no registrador eax.
Se retorna um float ou double, o valor é retornado pela FPU, no registrador st0.
Structs grandes são retornadas por meio de ponteiros também.

