#include <stdio.h>

extern void foo();
extern int sv;

int main() {
    if(sv)
        foo();
    return 0;
}
