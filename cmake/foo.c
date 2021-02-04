#include "foo.h"

extern "C" int g1 = 10;

void foo() {
    printf("\nThe value of global variable sv is:%d\n", g1);
}
