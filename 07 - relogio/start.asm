SYSCALL_WRITE equ 1
SYSCALL_SIGACTION equ 13
SYSCALL_PAUSE equ 34
SYSCALL_SETITIMER equ 38

SIGALRM equ 14
ITIMER_REAL equ 0

section .data
    msg db 'Timer interrupt', 10
    msg_len equ $ - msg

    errmsg db 'Erro ao configurar sigaction', 10
    errmsg_len equ $ - errmsg ; <-- Corrigido aqui

   
    ; Estrutura itimerval para setitimer
    ; { {tv_sec, tv_usec}, {tv_sec, tv_usec} }
    ; it_value.tv_sec, it_value.tv_usec
    ; it_interval.tv_sec, it_interval.tv_usec
    timer_val:
        dq 5, 0             ; it_value = 1 segundo (tv_sec = 1, tv_usec = 0)
        dq 5, 0             ; it_interval = 1 segundo (tv_sec = 1, tv_usec = 0)

section .text
    ;global _start
   global main
   global signal_handler
   global configura_action
   extern setup_sigaction
   extern act2
   extern act
   extern sigaction
   



main:
;_start:
   call setup_sigaction
   call configura_action
   call configura_timer
   call espera    




espera:
.loop:
    mov rax, SYSCALL_PAUSE
    syscall
    jmp .loop
    ret
    

configura_timer:
    ; Configura setitimer
    mov rax, SYSCALL_SETITIMER
    mov rdi, ITIMER_REAL
    lea rsi, [rel timer_val]    ; Ponteiro para a estrutura itimerval
    xor rdx, rdx                ; old_value = NULL
    syscall

    ret
    
configura_action:

  ; Chama sigaction(SIGALRM, &act, NULL)
    mov rdi, SIGALRM               ; SIGALRM
    lea rsi, [rel act]          ; &act
    xor rdx, rdx                ; NULL

    call sigaction
    ret

  mov rax, SYSCALL_SIGACTION
  mov rdi, SIGALRM
  mov rsi, act    ; Ponteiro para a nova sigaction
  xor rdx, rdx                ; oldact = NULL
  ;mov r10, 8                  ; Tamanho de sigset_t (8 bytes para x86-64)
  syscall
   
  ret

error:
    ; Escreve mensagem de erro
    mov rax, SYSCALL_WRITE
    mov rdi, 1                  ; stdout
    lea rsi, [rel errmsg]
    mov rdx, errmsg_len
    syscall

    mov rax, 60                 ; Syscall exit
    mov rdi, 1                  ; Código de saída 1 (erro)
    syscall

    
; --- Handler para SIGALRM ---
signal_handler:
    ; Salva os registradores que serão modificados
    push rax
    push rdx
    push rsi
    push rdi
    push rcx 
    
    ; Escreve mensagem
    mov rax, SYSCALL_WRITE
    mov rdi, 1                  ; stdout
    lea rsi, [rel msg]
    mov rdx, msg_len
    syscall

    ; Restaura os registradores
    pop rcx 
    pop rdi
    pop rsi
    pop rdx
    pop rax

    ret
