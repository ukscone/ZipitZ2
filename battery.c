/********************************************************
 * battery.c
 * Check Battery status bits
 * 
 * 
 * 05/02/10 Russell K. Davis
 * (Large) portions ripped from devmem2
 *     
 *  *****************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/mman.h>
  
#define MAP_SIZE 4096UL
#define GPIO_BASE 0x40E00000 /* PXA270 GPIO Register Base */

#define GPSR 0x18
#define GPCR 0x24

#define BATTSTAT1 99
#define BATTSTAT2 95
#define PWRBTN    1
#define LCD	  11
#define LID	  98


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

void gpio_write(void *map_base, int gpio, int val) {
	        volatile u32 *reg = (u32*)((u32)map_base + (val ? GPSR : GPCR) + regoffset(gpio));
		        *reg = 1 << (gpio & 31);
}


void gpio_dir(void *map_base, int gpio, int val) {
	        volatile u32 *reg = (u32*)((u32)map_base + 0xc+ regoffset(gpio));
	        if (val)
	                *reg |= 1 << (gpio & 31);
	        else
	                *reg &= ~(1 << (gpio & 31));
}


int main(int argc, char **argv) {
	int fd;
	int retval;
	void *map_base; 
	int battery1, battery2;
	int acpower;
	
	fd = open("/dev/mem", O_RDWR | O_SYNC);
   	if (fd < 0) exit(255);
	
    	map_base = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, GPIO_BASE);
	if(map_base == (void *) -1) exit(255);

	gpio_dir(map_base,95,0);
	gpio_dir(map_base,99,0);
	gpio_dir(map_base,83,1);

	
	battery1 = gpio_read(map_base, 99);
	battery2 = gpio_read(map_base, 95);
	acpower = gpio_read(map_base, 0);

		
	retval = (acpower*4)+(battery2*2)+battery1;

	if (retval == 4 || retval == 6) {
		gpio_write(map_base,83,0);
	} else {
		gpio_write(map_base,83,1);
	}
	
	if(munmap(map_base, MAP_SIZE) == -1) exit(255) ;
	close(fd);
	return retval;
}

