#ifndef _QSORT_H
#define _QSORT_H

#include <stdint.h>
#include <stdbool.h>

#define SIZE 10
int Q[SIZE] = {10, 9, 8, 7, 6, 5, 4, 3, 2, 1};

#define AP          (*(volatile uint32_t*)0x30002000)
												
#define X           (*(volatile uint32_t*)0x30002080)
#define Y           (*(volatile uint32_t*)0x30002084)

#endif