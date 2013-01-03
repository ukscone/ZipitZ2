/*******************************************
 * lcdbrightness.c
 * Russell K. Davis
 * (Large) portions ripped off from devmem2
 *
 ******************************************/
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/mman.h>
  
#define MAP_SIZE 4096UL
#define MAP_MASK ( MAP_SIZE - 1 )

typedef unsigned int u32;
static int fd = -1;

static int getmem(u32 addr){  
	void *map, *regaddr;
	u32 val;

	if (fd == -1) {
		fd = open("/dev/mem", O_RDWR | O_SYNC);
		if (fd<0) {
			perror("open(\"/dev/mem\")");
			exit(1);
		}
	}

	map = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, addr & ~MAP_MASK );

	if (map == (void*)-1 ) {
		perror("mmap()");
		exit(1);
	}

	regaddr = map + (addr & MAP_MASK);

	val = *(u32*) regaddr;
	munmap(0,MAP_SIZE);

	return val;
}

static void putmem(u32 addr, u32 val){
	void *map, *regaddr;
	static int fd = -1;

	if (fd == -1) {
		fd = open("/dev/mem", O_RDWR | O_SYNC);
		if (fd<0) {
			perror("open(\"/dev/mem\")");
			exit(1);
		}
	}
 
	map = mmap(0,MAP_SIZE,PROT_READ | PROT_WRITE,MAP_SHARED,fd,addr & ~MAP_MASK);
	if (map == (void*)-1 ) {
		perror("mmap()");
		exit(1);
	}
		 
	regaddr = map + (addr & MAP_MASK);

	*(u32*) regaddr = val;
	munmap(0,MAP_SIZE);
}

static void setreg(u32 addr, u32 mask, int shift, u32 val)
{
	u32 mem;

	mem = getmem(addr);
	mem &= ~(mask << shift);
	val &= mask;
	mem |= val << shift;
	putmem(addr, mem);   
}

int main(int argc, char *argv[]) {
	void *map_base ; 

	int period;
	int dcycle;	
	int prescale;

	period = atoi(argv[1]);
	prescale = atoi(argv[2]);
	dcycle = atoi(argv[3]);

	setreg(0x40E00054,0x00000003,22,2); 		//GAFR0L_11 -- GPIO 11 Alternative function
	setreg(0x40B00018,0xffffffff,0,period); 	//PWMPERVAL2 -- PWM2 Period Cycle Length
	setreg(0x40B00010, 0x000003f,0,prescale); 	// PWMCTL2_PRESCALE
	setreg(0x40B00010, 0x0000001,5,0); 		// PWMCTL2_SD -- PWM2 Abrupt Shutdown
	setreg(0x40B00014, 0x0000001,10,0); 		// PWMDUTY2_FDCYCLE 
	setreg(0x40B00014, 0x00003ff,0,dcycle); 	// PWM2 Duty Cycle
	setreg(0x41300004, 0x0000001,1,1); 		// CM PWM clock enabled


}

