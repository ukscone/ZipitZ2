/*****************************************************
 * Turn the ZipitZ2 KB LEDS ON
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
#define MAP_MASK (MAP_SIZE - 1)

#define KBLEDON "0x3ff"
#define GPIO_BASE 0x40C00004 /* PXA270 GPIO Register Base */

int main(int argc, char **argv) {
        int fd;
        void *map_base, *virt_addr;

        fd = open("/dev/mem", O_RDWR | O_SYNC);
        if (fd < 0) exit(255);

        map_base = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE , MAP_SHARED, fd, GPIO_BASE & ~MAP_MASK);
        if(map_base == (void *) -1) exit(255);


        virt_addr = map_base + (GPIO_BASE & MAP_MASK);
        *((unsigned long *) virt_addr) = strtoul(KBLEDON,0,0);

        if(munmap(map_base, MAP_SIZE) == -1) exit(255) ;
        close(fd);
}

