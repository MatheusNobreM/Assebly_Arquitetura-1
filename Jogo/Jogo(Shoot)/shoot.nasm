; Programa em Assembly (x86_64, Linux) que simula um duelo de faroeste.
; O jogador deve pressionar a tecla de espaço no momento certo para atirar primeiro e vencer.
; Usa chamadas de sistema (syscalls) para gerenciar entrada/saída, terminal e temporização.

; === Definições de constantes para chamadas de sistema ===
%define SYS_READ       0    ; Ler dados (ex.: teclado)
%define SYS_WRITE      1    ; Escrever dados (ex.: tela)
%define SYS_EXIT       60   ; Encerrar o programa
%define SYS_NANOSLEEP  35   ; Pausar execução por um tempo
%define SYS_IOCTL      16   ; Controlar dispositivos (ex.: terminal)
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
    tspec        resq 2    ; Estrutura para nanosleep (segundos e nanossegundos)
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
    mov qword [sig_action], sigint_handler ; Define função do manipulador
    mov qword [sig_action + 8], 0         ; sa_flags
    mov qword [sig_action + 16], SA_RESTORER ; sa_restorer
    mov qword [sig_action + 24], 0        ; sa_mask
    mov rax, SYS_SIGACTION                ; Configura manipulador
    mov rdi, SIGINT                       ; Sinal a ser tratado
    lea rsi, [sig_action]                 ; Endereço da estrutura
    xor rdx, rdx                          ; Sem máscara antiga - Zera o registrador rdx usando xor rdx, rdx (uma forma eficiente de definir rdx como 0).
    mov r10, 8                            ; Tamanho da máscara
    syscall

    call set_raw_mode ; Configura terminal em modo bruto

    ; === Exibir mensagem de introdução ===
    mov rdi, intro_msg
    call print_string

    mov r12, 1 ; Contador de passos (1 a 10)
.count_loop:
    cmp r12, 10
    ; A instrução cmp subtrai 10 de r12 internamente (sem alterar r12) e
    ; define flags no registrador de status para indicar o resultado (igual, maior ou menor)
    jne .print_step ; Se não for 10, exibe número
    
    ; === Exibir "10" ===
    mov rdi, number_10_str
    call print_string
    jmp .newline

.print_step:
    ; === Converter número para caractere e exibir ===
    mov rax, r12
    add al, '0'         ; Converte número para caractere ASCII
    mov [step_buf], al  ; Armazena no buffer
    mov byte [step_buf+1], 10 ; Adiciona nova linha
    
    mov rax, SYS_WRITE  ; Escreve no terminal
    mov rdi, STDOUT ; Define a saída como o terminal.
    mov rsi, step_buf ; Aponta para o buffer com o dígito e a nova linha.
    mov rdx, 2 ; Aponta para o buffer com o dígito e a nova linha.
    syscall

.newline:
    call flush_keyboard   ; Limpa entradas pendentes
    call sleep_1s         ; Espera 1 segundo
    call check_keypress   ; Verifica tecla pressionada
    cmp rax, 1
    je drew_early         ; Se tecla foi pressionada, jogador perde
    
    inc r12               ; Incrementa contador
    cmp r12, 11
    jne .count_loop       ; Continua até 10 passos

    ; === Exibir dica para atirar ===
    mov rdi, space_hint
    call print_string

    call flush_keyboard   ; Limpa entradas
    call get_random_delay ; Gera atraso aleatório (2-4s)
    call wait_draw_or_key ; Espera oponente sacar ou tecla
    cmp rax, 1
    je win                ; Se tecla pressionada, jogador vence

    ; === Oponente saca ===
    mov rdi, draw_msg
    call print_string

    call wait_2s_or_key   ; Espera 2s ou tecla
    cmp rax, 1
    je win                ; Se tecla pressionada, jogador vence

lose:
    ; === Exibir mensagem de derrota ===
    mov rdi, lose_msg
    call print_string
    jmp end_game

win:
    ; === Exibir mensagem de vitória ===
    mov rdi, win_msg
    call print_string
    jmp end_game

drew_early:
    ; === Exibir mensagem de tiro precoce ===
    mov rdi, early_msg
    call print_string
    jmp end_game

end_game:
    ; === Aguardar tecla para sair ===
    mov rdi, exit_msg
    call print_string
    call wait_key
    call restore_terminal ; Restaura terminal
    mov rax, SYS_EXIT     ; Encerra programa
    xor rdi, rdi
    syscall

; =====================
; Funções auxiliares
; =====================

; === Função: print_string ===
; Exibe uma string no terminal usando SYS_WRITE
print_string:
    push rsi
    push rdx
    push rax
    push rdi
    
    ; Calcular tamanho da string (até byte nulo)
    xor rcx, rcx
    mov rsi, rdi
.count_loop:
    lodsb
    test al, al
    jz .count_done
    inc rcx
    jmp .count_loop
.count_done:
    
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    pop rsi
    mov rdx, rcx
    syscall
    
    pop rax
    pop rdx
    pop rsi
    ret

; === Função: wait_key ===
; Lê uma tecla do teclado
wait_key:
    mov rax, SYS_READ
    mov rdi, STDIN ;Entrada padrão (teclado)
    mov rsi, key
    mov rdx, 1
    syscall
    ret

; === Função: check_keypress ===
; Verifica se uma tecla foi pressionada (não bloqueante)
check_keypress:
    ; Configurar pollfd para STDIN
    mov dword [pollfd], STDIN ; Entrada padrão (teclado)
    mov dword [pollfd + 4], POLLIN
    
    mov rax, SYS_POLL
    mov rdi, pollfd
    mov rsi, 1
    mov rdx, 0
    syscall
    
    test rax, rax
    jz .nokey ; Nenhuma tecla pressionada
    
    ; Ler tecla
    mov rax, SYS_READ
    mov rdi, STDIN ; Entrada padrão (teclado)
    mov rsi, key
    mov rdx, 1
    syscall
    
    cmp rax, 1
    jne .nokey
    mov rax, 1 ; Tecla pressionada
    ret
.nokey:
    xor rax, rax ; Nenhuma tecla
    ret

; === Função: flush_keyboard ===
; Limpa entradas pendentes do teclado
flush_keyboard:
.flush:
    call check_keypress
    cmp rax, 1
    je .flush
    ret

; === Função: sleep_1s ===
; Pausa por 1 segundo
sleep_1s:
    mov qword [tspec], 1
    mov qword [tspec+8], 0
    mov rax, SYS_NANOSLEEP
    mov rdi, tspec
    xor rsi, rsi
    syscall
    ret

; === Função: get_random_delay ===
; Gera atraso aleatório (2-4 segundos)
get_random_delay:
    mov rax, SYS_TIME
    xor rdi, rdi
    syscall
    
    ; Usar bits menos significativos para gerar número entre 2-4
    and eax, 0x3  ; 0-3
    add eax, 2    ; 2-5
    cmp eax, 4
    jle .ok
    mov eax, 4
.ok:
    mov r13d, eax ; Salva atraso em r13
    ret

; === Função: wait_draw_or_key ===
; Espera o atraso aleatório ou uma tecla
wait_draw_or_key:
    imul r13, 10  ; Converte atraso para décimos de segundo
    
.loop:
    call check_keypress
    cmp rax, 1
    je .reacted ; Tecla pressionada
    
    ; Esperar 0.1 segundo
    mov qword [tspec], 0
    mov qword [tspec+8], 100000000 ; 100ms
    mov rax, SYS_NANOSLEEP
    mov rdi, tspec
    xor rsi, rsi
    syscall
    
    dec r13
    jnz .loop
    
    xor rax, rax ; Tempo esgotado
    ret
.reacted:
    mov rax, 1 ; Tecla pressionada
    ret

; === Função: wait_2s_or_key ===
; Espera 2 segundos ou uma tecla
wait_2s_or_key:
    mov r14, 20 ; 20 x 0.1s = 2s
    
.loop:
    call check_keypress
    cmp rax, 1
    je .pressed ; Tecla pressionada
    
    ; Esperar 0.1 segundo
    mov qword [tspec], 0
    mov qword [tspec+8], 100000000 ; 100ms
    mov rax, SYS_NANOSLEEP
    mov rdi, tspec
    xor rsi, rsi
    syscall
    
    dec r14
    jnz .loop
    
    xor rax, rax ; Tempo esgotado
    ret
.pressed:
    mov rax, 1 ; Tecla pressionada
    ret

; === Função: set_raw_mode ===
; Configura o terminal em modo bruto (sem eco, sem buffer)
set_raw_mode:
    ; Obter configurações atuais do terminal
    mov rax, SYS_IOCTL ; Controlar dispositivos
    mov rdi, STDIN ; Entrada padrão (teclado)
    mov rsi, 0x5401 ; TCGETS
    mov rdx, old_termios
    syscall
    
    ; Copiar configurações para new_termios
    mov rsi, old_termios
    mov rdi, new_termios
    mov rcx, 48 ; Define rcx como 48, o número de bytes a serem copiados (tamanho da estrutura termios)
    rep movsb
    
    ; Desativar ECHO e ICANON
    mov rdi, new_termios
    and dword [rdi + 12], ~(ECHO | ICANON) ; Modifica o campo de flags da estrutura termios (no offset 12, que corresponde ao campo c_lflag).
    ; ECHO (8): Quando ativo, faz com que as teclas digitadas sejam exibidas no terminal.
    ; ICANON (2): Quando ativo, faz o terminal operar em modo canônico, onde a entrada é processada apenas após pressionar Enter.
    ; ~(ECHO | ICANON): Combina ECHO (8) e ICANON (2) com OR bit a bit (8 | 2 = 10), inverte com NOT (~10), e usa AND para desativar essas flags.
    ;Resultado: Desativa ECHO (teclas não aparecem na tela) e ICANON (teclas são lidas imediatamente, sem esperar Enter), configurando o modo bruto.


    ; Aplicar novas configurações
    mov rax, SYS_IOCTL ; Controlar dispositivos
    mov rdi, STDIN ; Entrada padrão (teclado)
    mov rsi, 0x5402 ; TCSETS
    mov rdx, new_termios ; Passa o endereço de new_termios, que contém as configurações modificadas (sem ECHO e ICANON)
    syscall
    ; Efeito: O terminal agora lê teclas imediatamente (sem esperar Enter) e não exibe as teclas digitadas

    
    ; Configurar modo não bloqueante
    mov rax, SYS_FCNTL
    mov rdi, STDIN ; Entrada padrão (teclado)
    mov rsi, 3 ; F_GETFL: Especifica o comando F_GETFL (3), que obtém as flags atuais do descritor.
    syscall
    
    mov rdi, STDIN ; Entrada padrão (teclado)
    mov rsi, 4 ; F_SETFL: Especifica o comando F_SETFL (4), que define novas flags.
    mov rdx, rax ; Copia as flags atuais (retornadas por F_GETFL) para rdx.
    or rdx, O_NONBLOCK ; Adiciona a flag O_NONBLOCK (04000) às flags existentes usando OR bit a bit.
    syscall
    ; Efeito: Leituras de STDIN (ex.: em check_keypress) não bloqueiam o programa.
    ; Se não houver tecla pressionada, a leitura retorna imediatamente, permitindo que o jogo continue sem pausas.
    ret

; === Função: restore_terminal ===
; Restaura configurações originais do terminal
restore_terminal:
    mov rax, SYS_IOCTL ; Controlar dispositivos
    mov rdi, STDIN ; Entrada padrão (teclado)
    mov rsi, 0x5402 ; TCSETS - obtém a estrutura termios do terminal
    mov rdx, old_termios
    syscall
    
    ; Restaurar flags de arquivo
    mov rax, SYS_FCNTL
    mov rdi, STDIN ; Entrada padrão (teclado)
    mov rsi, 3 ; F_GETFL
    syscall
    
    mov rdi, STDIN ; Entrada padrão (teclado)
    mov rsi, 4 ; F_SETFL
    mov rdx, rax
    and rdx, ~O_NONBLOCK
    syscall
    ret