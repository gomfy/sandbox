#include "foo.h"

extern "C" int g1 = 10;

void foo() {
    printf("The value of global variable g1 is: %d\n", g1);
}
