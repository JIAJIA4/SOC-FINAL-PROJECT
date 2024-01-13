#ifndef _MATMUL_H
#define _MATMUL_H

#include <stdint.h>
#include <stdbool.h>

#define SIZE 4

	int A[SIZE*SIZE] = {0, 1, 2, 3,
			0, 1, 2, 3,
			0, 1, 2, 3,
			0, 1, 2, 3,
	};
	int B[SIZE*SIZE] = {1, 2, 3, 4,
		5, 6, 7, 8,
		9, 10, 11, 12,
		13, 14, 15, 16,
	};
	int result[SIZE*SIZE];

#define AP          (*(volatile uint32_t*)0x30003000)
#define X           (*(volatile uint32_t*)0x30003080)
#define Y           (*(volatile uint32_t*)0x30003084)

#endif
