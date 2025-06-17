#include <stdio.h> //biblioteca padrao I/O
#include <stdlib.h> //controle de processos: exit. gerador n random
#include <unistd.h> // buffer, funçoes posix (read, write, sleep, unsleep)
#include <termios.h>//mexer diretamente no funcionamento do terminal (receber um dado sem que vc aperte enter)
#include <fcntl.h>//controla como o descritor de arquivo se comporta na leitura/escrita
#include <time.h>//manipulaçao de tempo

// Modo raw (sem buffer de linha, sem eco)
void set_input_mode(int enable) {
    static struct termios oldt, newt;
    if (!enable) {
        tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
    } else {
        tcgetattr(STDIN_FILENO, &oldt); // salva o estado atual
        newt = oldt;
        newt.c_lflag &= ~(ICANON | ECHO); // muda o comportamento
        tcsetattr(STDIN_FILENO, TCSANOW, &newt); // aplica a nova configuração
    }
}

// Liga/desliga nonblocking
void set_nonblocking(int enable) {
    int flags = fcntl(STDIN_FILENO, F_GETFL, 0);
    if (enable)
        fcntl(STDIN_FILENO, F_SETFL, flags | O_NONBLOCK);
    else
        fcntl(STDIN_FILENO, F_SETFL, flags & ~O_NONBLOCK);
}

// Tenta ler um caractere não bloqueante.
// Retorna 1 se leu, 0 se não.
int try_read_char(char *out) {
    int r = read(STDIN_FILENO, out, 1);
    return r == 1;
}

int main() {
    srand(time(NULL));
    set_input_mode(1);
    set_nonblocking(1);

    printf("COWBOY SHOOTOUT -\n");
    printf("YOU ARE BACK TO BACK\n");
    printf("TAKE 10 PACES...\n");
    fflush(stdout);

    // Contagem de 1 a 10, detectando tiro precoce
    for (int i = 1; i <= 10; i++) {
        printf("%d\n", i);
        fflush(stdout);
        // Em vez de sleep(1), faz 10 ciclos de 100ms checando teclas:
        for (int t = 0; t < 10; t++) {
            char c;
            if (try_read_char(&c)) {
                printf("YOU DREW TOO EARLY!\n");
                printf("YOU ARE DEAD.\n");
                goto end;
            }
            usleep(100000);
        }
    }

    // Delay aleatório (2–4s) antes do DRAW (não detecta tecla aqui)
    int delay = rand() % 3 + 2;
    time_t start = time(NULL);
    while (time(NULL) - start < delay) {
        usleep(100000);
    }

    //  Momento do DRAW
    printf("HE DRAWS...\n");
    fflush(stdout);

    //  2 segundos para você reagir
    start = time(NULL);
    int reacted = 0;
    while (time(NULL) - start < 2) {
        char c;
        if (try_read_char(&c)) {
            reacted = 1;
            break;
        }
        usleep(100000);
    }

    if (reacted) {
        printf("BUT YOU SHOOT FIRST.\n");
        printf("YOU KILLED HIM.\n");
    } else {
        printf("AND SHOOTS...\n");
        printf("YOU ARE DEAD.\n");
    }

end:
    printf("\nPress any key to exit.\n");
    fflush(stdout);
    // espera tecla final antes de restaurar
    char dummy;
    while (!try_read_char(&dummy)) {
        usleep(100000);
    }

    set_input_mode(0);
    set_nonblocking(0);
    return 0;
}