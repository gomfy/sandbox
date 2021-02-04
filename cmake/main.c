#include <stdio.h>

extern void foo();
extern void bar(int x);
extern int g1;

int main() {
    int l1 = 1;
    if(g1) {
        foo();
	bar(l1);
    }
    return 0;
}
