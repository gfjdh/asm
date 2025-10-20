#include <stdio.h>
int main() {
    for (char i = 'a'; i <= 'z'; i++) {
        printf("%c", i);
        if (i == 'a' + 12)
            printf("\n");
        else
            printf(" ");
    }
    return 0;
}