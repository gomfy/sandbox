#include <stdio.h>
#include <stdlib.h>

extern void foo(const char*);

int main() {
    char fname[] = "file.txt";
    printf("fname: %s\n",fname);
    foo(fname);
    return 0;
}
