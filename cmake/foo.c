#include "foo.h"

extern "C" int sv = 10;

void foo() {
    printf("\nThe value of global variable sv is:%d\n", sv);
}
