/*****************************************************
 * Read value of the ZipitZ2 AC Mains GPIO with 
 * simple error checking.
 * Returns 0 for battery, 1 for mains, 255 for error
 *
 * 02/02/10 Russell K. Davis
 * (Large) portions ripped from devmem2
 *
 ****************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/mman.h>
  
#define MAP_SIZE 4096UL

#define GPIO 0	/* AC Power */
#define GPIO_BASE 0x40E00000 /* PXA270 GPIO Register Base */

typedef unsigned long u32;

int regoffset(int gpio) {
	if (gpio < 32) return 0;
	if (gpio < 64) return 4;
	if (gpio < 96) return 8;
	return 0x100;
}

int gpio_read(void *map_base, int gpio) {
	volatile u32 *reg = (u32*)((u32)map_base + regoffset(gpio));
	return (*reg >> (gpio&31)) & 1;
}

int main(int argc, char **argv) {
	int fd;
	int retval;
	void *map_base; 

	fd = open("/dev/mem", O_RDONLY | O_SYNC);
   	if (fd < 0) exit(255);
	
    	map_base = mmap(0, MAP_SIZE, PROT_READ, MAP_SHARED, fd, GPIO_BASE);
	if(map_base == (void *) -1) exit(255);

	switch(gpio_read(map_base,GPIO))
	{
		case 0:
			/* battery */
			retval = 0;
			break;
		case 1:
			/* mains */
			retval = 1;
			break;
		default:
			/* will never reach here unless something has gone terribly wrong */
			retval = 255;
	}

	if(munmap(map_base, MAP_SIZE) == -1) exit(255) ;
	close(fd);
	return retval;
}
