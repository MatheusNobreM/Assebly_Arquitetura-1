#include <stdio.h>
#include <signal.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/time.h>






extern void signal_handler(int);


struct sigaction act;
struct sigaction *act2 = &act;

int setup_sigaction(void)
{
    memset(&act, 0, sizeof(act));  // Zera a struct

    act.sa_handler = signal_handler;      // Ponteiro para handler
    sigemptyset(&act.sa_mask);     // Limpa máscara de sinais
    act.sa_flags = 0;              // Sem flags adicionais
 /*   
    // Configura o sinal SIGALRM
    if (sigaction(SIGALRM, &act, NULL) == -1) {
        perror("Erro ao configurar sigaction");
        return -1;
    }
 */   
    return 0;
}







