#include <stdio.h>

int sum(int a, int b) {
    int result = a + b;
    if (result > 10) {
        result += 5;
    }
    return result;
}

int main(void) {
    printf("%d\n", sum(7, 8));
    return 0;
}
