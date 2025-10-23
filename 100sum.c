#include <stdio.h>
int main() {
    int sum = 0;
    scanf("%d", &sum);
    for (int i = sum - 1; i > 0; i--) {
        sum += i;
    }
    printf("%d\n", sum);
    return 0;
}