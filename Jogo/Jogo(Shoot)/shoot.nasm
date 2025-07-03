%define SYS_READ       0    
%define SYS_WRITE      1    
%define SYS_EXIT       60   ; Encerrar o programa
%define SYS_NANOSLEEP  35   ; Pausar  
%define SYS_IOCTL      16   ; terminal
%define SYS_FCNTL      72   ; Configurar opções de arquivos
%define SYS_TIME       201  ; Obter tempo atual
%define SYS_SIGACTION  13   ; Configurar manipuladores de sinais
%define SYS_POLL       7    ; Verificar eventos (ex.: tecla pressionada)

; === Descritores de arquivos ===
%define STDIN          0    ; Entrada padrão (teclado)
%define STDOUT         1    ; Saída padrão (tela)

; === Constantes para configuração do terminal e sinais ===
%define ICANON         2          ; Modo canônico (processamento de linha)
%define ECHO           8          ; Eco de entrada (mostrar teclas digitadas)
%define TCSANOW        0          ; Aplicar mudanças no terminal imediatamente
%define O_NONBLOCK     04000      ; Modo não bloqueante para leitura
%define SIGINT         2          ; Sinal de interrupção (Ctrl+C)
%define SA_RESTORER    0x04000000 ; Flag para restaurar estado após sinal
%define POLLIN         0x001      ; Evento de leitura disponível (tecla pressionada)

section .data
    ; === Mensagens exibidas durante o jogo ===
    intro_msg     db "COWBOY SHOOTOUT -",10,"YOU ARE BACK TO BACK",10,"TAKE 10 PACES...",10,10,0
    early_msg     db 10,"YOU DREW TOO EARLY!",10,"YOU ARE DEAD.",10,10,0
    draw_msg      db 10,"HE DRAWS...",10,0
    win_msg       db "BUT YOU SHOOT FIRST.",10,"YOU KILLED HIM.",10,10,0
    lose_msg      db "AND SHOOTS...",10,"YOU ARE DEAD.",10,10,0
    exit_msg      db "Press any key to exit.",10,10,0
    space_hint    db "Press SPACE to shoot!",10,0
    number_10_str db "10",10 ; String para o número 10

section .bss
    ; === Variáveis reservadas (inicializadas como zero) ===
    key          resb 1    ; Armazena uma tecla lida - resb N: Reserva N bytes na memória (1 byte = 8 bits).
    step_buf     resb 2    ; Buffer para números de 1 a 9 (dígito + nova linha)
    tspec        resq 2    ; Estrutura para nanosleep
    old_termios  resb 48   ; Configurações originais do terminal - resq N: Reserva N palavras de 64 bits (quad words, 8 bytes cada).
    new_termios  resb 48   ; Configurações modificadas do terminal
    sig_action   resb 152  ; Estrutura para manipulador de sinal
    pollfd       resb 8    ; Estrutura para poll (verificar entrada)

section .text
global _start

; =====================
; Handler para SIGINT (Ctrl+C)
; Restaura o terminal e encerra o programa
; =====================
sigint_handler:
    call restore_terminal ; Restaura configurações do terminal
    mov rax, SYS_EXIT    ; Syscall para sair
    xor rdi, rdi         ; Código de saída 0
    syscall

; =====================
; Programa principal
; Exibe introdução, conta 10 passos, espera o momento do duelo e verifica o resultado
; =====================
_start:
    ; === Configurar manipulador de SIGINT (Ctrl+C) ===
    mov qword [sig_action], sigint_handler   
    mov qword [sig_action + 8], 0            
    mov qword [sig_action + 16], SA_RESTORER 
    mov qword [sig_action + 24], 0           ; sa_mask
    mov rax, SYS_SIGACTION                   
    mov rdi, SIGINT                          ; Sinal a ser tratado
    lea rsi, [sig_action]                    ; Endereço da estrutura
    xor rdx, rdx                             
    mov r10, 8                               ; Tamanho da máscara
    syscall

    call set_raw_mode ; Configura terminal em modo bruto

    ; === Exibir mensagem de introdução ===
    mov rdi, intro_msg
    call print_string

    mov r12, 1 ; Contador de passos
.count_loop:
    cmp r12, 10
    ;  subtrai 10 de r12 internamente (sem alterar r12) e
    ; define flags no registrador de status para indicar o resultado (igual, maior ou menor)
    jne .print_step ; !10, exibe número
    
    ; === Exibir "10" ===
    mov rdi, number_10_str
    call print_string
    jmp .newline

.print_step:
    mov rax, r12
    add al, '0'         ; Converte número para caractere ASCII
    mov [step_buf], al  ; Armazena no buffer
    mov byte [step_buf+1], 10 ; Adiciona nova linha
    
    mov rax, SYS_WRITE  
    mov rdi, STDOUT     ; Define a saída como o terminal.
    mov rsi, step_buf   ; Aponta para o buffer com o dígito e a nova linha.
    mov rdx, 2          
    syscall

.newline:
    call flush_keyboard   ; Limpa entradas pendentes do teclado para evitar leituras acidentais
    call sleep_1s     
    call check_keypress   ; Verifica se o jogador pressionou uma tecla durante a contagem
    cmp rax, 1            ; Compara o retorno de check_keypress com 1 (tecla pressionada)
    je drew_early         ; se keypress
    
    inc r12               ; Incrementa o contador de passos
    cmp r12, 11           ; Verifica se o contador atingiu 11
    jne .count_loop       ; Se não atingiu 11, volta ao início do loop para o próximo passo

    ; === Exibir dica para atirar ===
    mov rdi, space_hint   ; Carrega o endereço ("Press SPACE to shoot!")
    call print_string     

    call flush_keyboard   ; Limpa entradas pendentes do teclado antes do momento do duelo
    call get_random_delay ; Gera um atraso aleatório para o oponente sacar
    call wait_draw_or_key ; Espera o atraso ou uma tecla do jogador
    cmp rax, 1            ; Verifica se o jogador pressionou uma tecla (retorno 1 de wait_draw_or_key)
    je win                ; Se tecla foi pressionada a tempo(vitória)

    ; === Oponente saca ===
    mov rdi, draw_msg     ; Carrega o endereço("HE DRAWS...")
    call print_string    

    call wait_2s_or_key   
    cmp rax, 1            
    je win                

lose:
    ; === Exibir mensagem de derrota ===
    mov rdi, lose_msg     ; Carrega o endereço da string lose_msg ("AND SHOOTS... YOU ARE DEAD.")
    call print_string     ; Exibe a mensagem de derrota no terminal
    jmp end_game          ; Pula para o fim do jogo

win:
    ; === Exibir mensagem de vitória ===
    mov rdi, win_msg      ; Carrega o endereço da string win_msg ("BUT YOU SHOOT FIRST. YOU KILLED HIM.")
    call print_string     ; Exibe a mensagem de vitória no terminal
    jmp end_game          ; Pula para o fim do jogo

drew_early:
    ; === Exibir mensagem de tiro precoce ===
    mov rdi, early_msg    ; Carrega o endereço da string early_msg ("YOU DREW TOO EARLY! YOU ARE DEAD.")
    call print_string     ; Exibe a mensagem de tiro precoce no terminal
    jmp end_game          ; Pula para o fim do jogo

end_game:
    ; === Aguardar tecla para sair ===
    mov rdi, exit_msg     ; Carrega o endereço da string exit_msg ("Press any key to exit.")
    call print_string     ; Exibe a mensagem no terminal
    call wait_key         ; Aguarda o jogador pressionar qualquer tecla para sair
    call restore_terminal ; Restaura as configurações originais do terminal
    mov rax, SYS_EXIT     ; Prepara a chamada de sistema para encerrar o programa
    xor rdi, rdi          ; Define o código de saída como 0 (sucesso)
    syscall               ; Executa a chamada para encerrar o programa

; =====================
; Funções auxiliares
; =====================

; === Função: print_string ===
; Exibe uma string no terminal usando SYS_WRITE
print_string:
    push rsi              ; Salva rsi na pilha para preservá-lo
    push rdx              ; Salva rdx na pilha para preservá-lo
    push rax              ; Salva rax na pilha para preservá-lo
    push rdi              ; Salva rdi na pilha para preservá-lo
    
    ; Calcular tamanho da string (até byte nulo)
    xor rcx, rcx          ; Zera rcx para contar o tamanho da string
    mov rsi, rdi          ; Copia o endereço da string (em rdi) para rsi
.count_loop:
    lodsb                 ; Carrega o próximo byte da string em al e incrementa rsi
    test al, al           ; Verifica se o byte é 0 (nulo, fim da string)
    jz .count_done        ; Se for nulo, pula para count_done
    inc rcx               ; Incrementa o contador de bytes
    jmp .count_loop       ; Volta ao loop para o próximo byte
.count_done:
    
    mov rax, SYS_WRITE    ; Prepara a chamada de sistema SYS_WRITE para escrever no terminal
    mov rdi, STDOUT       ; Define o descritor de saída como STDOUT (tela)
    pop rsi               ; Restaura o endereço original da string em rsi
    mov rdx, rcx          ; Define o número de bytes a escrever (contado em rcx)
    syscall               ; Executa a chamada para escrever a string no terminal
    
    pop rax               ; Restaura rax da pilha
    pop rdx               ; Restaura rdx da pilha
    pop rsi               ; Restaura rsi da pilha
    ret                   ; Retorna ao chamador

; === Função: wait_key ===
; Lê uma tecla do teclado
wait_key:
    mov rax, SYS_READ     ; Prepara a chamada de sistema SYS_READ para ler do teclado
    mov rdi, STDIN        ; Define o descritor de entrada como STDIN (teclado)
    mov rsi, key          ; Define o endereço da variável key como destino da tecla lida
    mov rdx, 1            ; Define que 1 byte será lido (uma tecla)
    syscall               ; Executa a chamada para ler a tecla
    ret                   ; Retorna ao chamador

; === Função: check_keypress ===
; Verifica se uma tecla foi pressionada (não bloqueante)
check_keypress:
    ; Configurar pollfd para STDIN
    mov dword [pollfd], STDIN ; Define o descritor de arquivo como STDIN na estrutura pollfd
    mov dword [pollfd + 4], POLLIN ; Define o evento POLLIN (entrada disponível) na estrutura pollfd
    
    mov rax, SYS_POLL     ; Prepara a chamada de sistema SYS_POLL para verificar eventos
    mov rdi, pollfd       ; Passa o endereço da estrutura pollfd
    mov rsi, 1            ; Define que 1 descritor de arquivo será verificado
    mov rdx, 0            ; Define timeout como 0 (retorna imediatamente)
    syscall               ; Executa a chamada para verificar se há entrada
    
    test rax, rax         ; Verifica se rax é 0 (nenhum evento)
    jz .nokey             ; Se rax for 0, pula para nokey (nenhuma tecla pressionada)
    
    ; Ler tecla
    mov rax, SYS_READ     ; Prepara a chamada SYS_READ para ler a tecla
    mov rdi, STDIN        ; Define o descritor de entrada como STDIN
    mov rsi, key          ; Define o endereço da variável key como destino
    mov rdx, 1            ; Define que 1 byte será lido
    syscall               ; Executa a chamada para ler a tecla
    
    cmp rax, 1            ; Verifica se 1 byte foi lido (tecla pressionada)
    jne .nokey            ; Se não, pula para nokey (nenhuma tecla)
    mov rax, 1            ; Define rax como 1 (indica que uma tecla foi pressionada)
    ret                   ; Retorna ao chamador
.nokey:
    xor rax, rax          ; Zera rax (indica que nenhuma tecla foi pressionada)
    ret                   ; Retorna ao chamador

; === Função: flush_keyboard ===
; Limpa entradas pendentes do teclado
flush_keyboard:
.flush:
    call check_keypress   ; Chama check_keypress para verificar se há tecla pendente
    cmp rax, 1            ; Verifica se uma tecla foi detectada
    je .flush             ; Se sim, volta ao início para limpar mais teclas
    ret                   ; Retorna quando não há mais teclas pendentes

; === Função: sleep_1s ===
; Pausa por 1 segundo
sleep_1s:
    mov qword [tspec], 1  ; Define 1 segundo na estrutura tspec (campo de segundos)
    mov qword [tspec+8], 0 ; Define 0 nanossegundos na estrutura tspec
    mov rax, SYS_NANOSLEEP ; Prepara a chamada de sistema SYS_NANOSLEEP para pausar
    mov rdi, tspec        ; Passa o endereço da estrutura tspec
    xor rsi, rsi          ; Define rsi como 0 (sem estrutura para tempo restante)
    syscall               ; Executa a chamada para pausar por 1 segundo
    ret                   ; Retorna ao chamador

; === Função: get_random_delay ===
; Gera atraso aleatório (2-4 segundos)
get_random_delay:
    mov rax, SYS_TIME     ; Prepara a chamada de sistema SYS_TIME para obter o tempo atual
    xor rdi, rdi          ; Define rdi como 0 (argumento padrão para SYS_TIME)
    syscall               ; Executa a chamada, retornando o tempo em segundos em rax
    
    ; Usar bits menos significativos para gerar número entre 2-4
    and eax, 0x3          ; Máscara para obter os 2 bits menos significativos (0 a 3)
    add eax, 1            ; Adiciona 2 para obter um valor entre 2 e 5
    cmp eax, 2           ; Verifica se o valor é maior que 2
    jle .ok               ; Se menor ou igual a 4, pula para ok
    mov eax, 2            ; Se maior, limita o valor a 2
.ok:
    mov r13d, eax         ; Salva o atraso (2 a 4 segundos) em r13
    ret                   ; Retorna ao chamador

; === Função: wait_draw_or_key ===
; Espera o atraso aleatório ou uma tecla
wait_draw_or_key:
    imul r13, 10          ; Multiplica o atraso (em r13) por 10 para converter em décimos de segundo
.loop:
    call check_keypress   ; Verifica se uma tecla foi pressionada
    cmp rax, 1            ; Compara o retorno com 1 (tecla pressionada)
    je .reacted           ; Se tecla foi pressionada, pula para reacted
    
    ; Esperar 0.1 segundo
    mov qword [tspec], 0  ; Define 0 segundos na estrutura tspec
    mov qword [tspec+8], 100000000 ; Define 100 milissegundos (0.1s) na estrutura tspec
    mov rax, SYS_NANOSLEEP ; Prepara a chamada SYS_NANOSLEEP para pausar
    mov rdi, tspec        ; Passa o endereço da estrutura tspec
    xor rsi, rsi          ; Define rsi como 0 (sem estrutura para tempo restante)
    syscall               ; Executa a chamada para pausar por 0.1 segundo
    
    dec r13               ; Decrementa o contador de décimos de segundo
    jnz .loop             ; Se r13 não for 0, volta ao início do loop
    
    xor rax, rax          ; Define rax como 0 (tempo esgotado, sem tecla)
    ret                   ; Retorna ao chamador
.reacted:
    mov rax, 1            ; Define rax como 1 (tecla pressionada)
    ret                   ; Retorna ao chamador

; === Função: wait_2s_or_key ===
; Espera 2 segundos ou uma tecla
wait_2s_or_key:
    mov r14, 20           ; Define r14 como 20 (20 x 0.1s = 2 segundos)
.loop:
    call check_keypress   ; Verifica se uma tecla foi pressionada
    cmp rax, 1            ; Compara o retorno com 1 (tecla pressionada)
    je .pressed           ; Se tecla foi pressionada, pula para pressed
    
    ; Esperar 0.1 segundo
    mov qword [tspec], 0  ; Define 0 segundos na estrutura tspec
    mov qword [tspec+8], 100000000 ; Define 100 milissegundos (0.1s) na estrutura tspec
    mov rax, SYS_NANOSLEEP ; Prepara a chamada SYS_NANOSLEEP para pausar
    mov rdi, tspec        ; Passa o endereço da estrutura tspec
    xor rsi, rsi          ; Define rsi como 0 (sem estrutura para tempo restante)
    syscall               ; Executa a chamada para pausar por 0.1 segundo
    
    dec r14               ; Decrementa o contador de décimos de segundo
    jnz .loop             ; Se r14 não for 0, volta ao início do loop
    
    xor rax, rax          ; Define rax como 0 (tempo esgotado, sem tecla)
    ret                   ; Retorna ao chamador
.pressed:
    mov rax, 1            ; Define rax como 1 (tecla pressionada)
    ret                   ; Retorna ao chamador

; === Função: set_raw_mode ===
; Configura o terminal em modo bruto (sem eco, sem buffer)
set_raw_mode:
    ; Obter configurações atuais do terminal
    mov rax, SYS_IOCTL    ; Prepara a chamada de sistema SYS_IOCTL para controlar dispositivos
    mov rdi, STDIN        ; Define o descritor de entrada como STDIN (teclado)
    mov rsi, 0x5401       ; Define o comando TCGETS (0x5401) para obter configurações do terminal
    mov rdx, old_termios  ; Define old_termios como destino das configurações atuais
    syscall               ; Executa a chamada para salvar configurações em old_termios
    
    ; Copiar configurações para new_termios
    mov rsi, old_termios  ; Define o endereço de origem como old_termios
    mov rdi, new_termios  ; Define o endereço de destino como new_termios
    mov rcx, 48           ; Define rcx como 48, o número de bytes a serem copiados (tamanho da estrutura termios)
    rep movsb             ; Copia 48 bytes de old_termios para new_termios
    
    ; Desativar ECHO e ICANON
    mov rdi, new_termios  ; Carrega o endereço de new_termios
    and dword [rdi + 12], ~(ECHO | ICANON) ; Desativa as flags ECHO e ICANON no campo c_lflag (offset 12)
    ; ECHO (8): Quando ativo, faz com que as teclas digitadas sejam exibidas no terminal.
    ; ICANON (2): Quando ativo, faz o terminal operar em modo canônico, onde a entrada é processada apenas após pressionar Enter.
    ; ~(ECHO | ICANON): Combina ECHO (8) e ICANON (2) com OR bit a bit (8 | 2 = 10), inverte com NOT (~10), e usa AND para desativar essas flags.
    ; Resultado: Desativa ECHO (teclas não aparecem na tela) e ICANON (teclas são lidas imediatamente, sem esperar Enter), configurando o modo bruto.

    ; Aplicar novas configurações
    mov rax, SYS_IOCTL    ; Prepara a chamada SYS_IOCTL para aplicar configurações
    mov rdi, STDIN        ; Define o descritor de entrada como STDIN
    mov rsi, 0x5402       ; Define o comando TCSETS (0x5402) para aplicar configurações
    mov rdx, new_termios  ; Passa o endereço de new_termios, que contém as configurações modificadas
    syscall               ; Executa a chamada para aplicar o modo bruto ao terminal
    ; Efeito: O terminal agora lê teclas imediatamente (sem esperar Enter) e não exibe as teclas digitadas

    ; Configurar modo não bloqueante
    mov rax, SYS_FCNTL    ; Prepara a chamada de sistema SYS_FCNTL para manipular opções de arquivo
    mov rdi, STDIN        ; Define o descritor de entrada como STDIN
    mov rsi, 3            ; Define o comando F_GETFL (3) para obter as flags atuais
    syscall               ; Executa a chamada, retornando as flags em rax
    
    mov rdi, STDIN        ; Define o descritor de entrada como STDIN
    mov rsi, 4            ; Define o comando F_SETFL (4) para definir novas flags
    mov rdx, rax          ; Copia as flags atuais (retornadas por F_GETFL) para rdx
    or rdx, O_NONBLOCK    ; Adiciona a flag O_NONBLOCK (04000) às flags existentes usando OR bit a bit
    syscall               ; Executa a chamada para aplicar o modo não bloqueante
    ; Efeito: Leituras de STDIN (ex.: em check_keypress) não bloqueiam o programa
    ret                   ; Retorna ao chamador

; === Função: restore_terminal ===
; Restaura configurações originais do terminal
restore_terminal:
    mov rax, SYS_IOCTL    ; Prepara a chamada de sistema SYS_IOCTL para controlar dispositivos
    mov rdi, STDIN        ; Define o descritor de entrada como STDIN (teclado)
    mov rsi, 0x5402       ; Define o comando TCSETS (0x5402) para aplicar configurações
    mov rdx, old_termios  ; Passa o endereço de old_termios, com as configurações originais
    syscall               ; Executa a chamada para restaurar as configurações do terminal
    
    ; Restaurar flags de arquivo
    mov rax, SYS_FCNTL    ; Prepara a chamada SYS_FCNTL para manipular opções de arquivo
    mov rdi, STDIN        ; Define o descritor de entrada como STDIN
    mov rsi, 3            ; Define o comando F_GETFL (3) para obter as flags atuais
    syscall               ; Executa a chamada, retornando as flags em rax
    
    mov rdi, STDIN        ; Define o descritor de entrada como STDIN
    mov rsi, 4            ; Define o comando F_SETFL (4) para definir novas flags
    mov rdx, rax          ; Copia as flags atuais para rdx
    and rdx, ~O_NONBLOCK  ; Remove a flag O_NONBLOCK usando AND com NOT para restaurar o modo bloqueante
    syscall               ; Executa a chamada para aplicar as flags restauradas
    ret                   ; Retorna ao chamador