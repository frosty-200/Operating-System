#include "lib.h"
#include "stdint.h"

int main(void)
{
    while (1) {
        printf("\n hello there from user 1\n");
        waitu();
	
	for(int i = 0; i < 10; i++)
	{
		printf("%d", i);
	}
    }
    return 0;
}
