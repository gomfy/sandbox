#include <stdio.h>

#ifdef __cplusplus
extern "C" {
	void bar(int);
}
#else
void bar(int);
#endif
