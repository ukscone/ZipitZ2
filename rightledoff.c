/*****************************************************
 * Turn the ZipitZ2 righthand LED OFF
 * simple error checking.
 *
 * 05/02/10 Russell K. Davis
 * (Large) portions ripped from devmem2
 *
 ****************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/mman.h>
  
#define MAP_SIZE 4096UL

#define GPIO 10
#define GPIO_BASE 0x40E00000 /* PXA270 GPIO Register Base */

#define GPSR 0x18
#define GPCR 0x24

typedef unsigned long u32;

int regoffset(int gpio) {
	if (gpio < 32) return 0;
	if (gpio < 64) return 4;
	if (gpio < 96) return 8;
	return 0x100;
}

void gpio_set(void *map_base, int gpio, int val) {
        volatile u32 *reg = (u32*)((u32)map_base + (val ? GPSR : GPCR) + regoffset(gpio));
        *reg = 1 << (gpio & 31);
}

int main(int argc, char **argv) {
	int fd;
	int retval;
	void *map_base; 

	fd = open("/dev/mem", O_RDWR | O_SYNC);
   	if (fd < 0) exit(255);
	
    	map_base = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE , MAP_SHARED, fd, GPIO_BASE);
	if(map_base == (void *) -1) exit(255);

	gpio_set(map_base, GPIO, 1);

	if(munmap(map_base, MAP_SIZE) == -1) exit(255) ;
	close(fd);
	return retval;
}
