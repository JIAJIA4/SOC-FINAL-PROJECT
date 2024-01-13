#ifndef __FIR_H__
#define __FIR_H__

#include <stdint.h>
#include <stdbool.h>

#define AP          (*(volatile uint32_t*)0x30001000)

#define data_len    (*(volatile uint32_t*)0x30001010)

#define tap0        (*(volatile uint32_t*)0x30001040)
#define tap1        (*(volatile uint32_t*)0x30001044)
#define tap2        (*(volatile uint32_t*)0x30001048)
#define tap3        (*(volatile uint32_t*)0x3000104c)
#define tap4        (*(volatile uint32_t*)0x30001050)
#define tap5        (*(volatile uint32_t*)0x30001054)
#define tap6        (*(volatile uint32_t*)0x30001058)
#define tap7        (*(volatile uint32_t*)0x3000105c)
#define tap8        (*(volatile uint32_t*)0x30001060)
#define tap9        (*(volatile uint32_t*)0x30001064)
#define tap10       (*(volatile uint32_t*)0x30001068)

#define X           (*(volatile uint32_t*)0x30001080)
#define Y           (*(volatile uint32_t*)0x30001084) 

int outputsignal[64];

#endif
