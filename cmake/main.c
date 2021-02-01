#include "foo.h"

extern int sv;

int main() {
    if(sv > 0)
        printf("\nsv is positive\n");
    else
        printf("\nsv is negative\n");
    foo();
    return 0;
}
