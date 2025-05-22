#include <stdio.h>

void print_array_int(int* v, int n) {
    for (int i = 0; i < n; i++)
        printf("%d ", v[i]);
    printf("\n");
}
