#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#ifdef _WIN32
#include <windows.h>
#define CLEAR "cls"
#define SLEEP(ms) Sleep(ms)
#else
#include <unistd.h>
#define CLEAR "clear"
#define SLEEP(ms) usleep((ms) * 1000)
#endif

int main() {
    srand(time(NULL));

    printf("COWBOY SHOOTOUT\n");
    printf("YOU ARE BACK TO BACK\n");
    printf("TAKE 10 PACES...\n");
    printf("DON'T PRESS ENTER TOO EARLY OR YOU DIE!\n\n");

    // Contagem de 1 a 10
    for (int i = 1; i <= 10; i++) {
        printf("%d\n", i);
        fflush(stdout);
        SLEEP(1000);  // 1 segundo entre passos
    }

    // Espera aleatória (2–4 segundos)
    int delay = rand() % 3 + 2;
    printf("\nGet ready...\n");
    SLEEP(delay * 1000);

    // Hora do DRAW
    printf("DRAW!\n");
    printf("Pressione ENTER agora!\n");

    clock_t start = clock();
    getchar();  // Aguarda ENTER
    clock_t end = clock();

    double reaction_time = (double)(end - start) / CLOCKS_PER_SEC;

    if (reaction_time < 2.0) {
        printf("You shot first! You win!\n");
    } else {
        printf("Too slow... You're dead.\n");
    }

    return 0;
}
