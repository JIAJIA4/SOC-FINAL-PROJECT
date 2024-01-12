# 0 "matmul.c"
# 1 "/home/ubuntu/Desktop/Final_Project/testbench/FP//"
# 0 "<built-in>"
# 0 "<command-line>"
# 1 "matmul.c"
# 1 "matmul.h" 1



# 1 "/opt/riscv/lib/gcc/riscv32-unknown-elf/12.1.0/include/stdint.h" 1 3 4
# 11 "/opt/riscv/lib/gcc/riscv32-unknown-elf/12.1.0/include/stdint.h" 3 4
# 1 "/opt/riscv/lib/gcc/riscv32-unknown-elf/12.1.0/include/stdint-gcc.h" 1 3 4
# 34 "/opt/riscv/lib/gcc/riscv32-unknown-elf/12.1.0/include/stdint-gcc.h" 3 4

# 34 "/opt/riscv/lib/gcc/riscv32-unknown-elf/12.1.0/include/stdint-gcc.h" 3 4
typedef signed char int8_t;


typedef short int int16_t;


typedef long int int32_t;


typedef long long int int64_t;


typedef unsigned char uint8_t;


typedef short unsigned int uint16_t;


typedef long unsigned int uint32_t;


typedef long long unsigned int uint64_t;




typedef signed char int_least8_t;
typedef short int int_least16_t;
typedef long int int_least32_t;
typedef long long int int_least64_t;
typedef unsigned char uint_least8_t;
typedef short unsigned int uint_least16_t;
typedef long unsigned int uint_least32_t;
typedef long long unsigned int uint_least64_t;



typedef int int_fast8_t;
typedef int int_fast16_t;
typedef int int_fast32_t;
typedef long long int int_fast64_t;
typedef unsigned int uint_fast8_t;
typedef unsigned int uint_fast16_t;
typedef unsigned int uint_fast32_t;
typedef long long unsigned int uint_fast64_t;




typedef int intptr_t;


typedef unsigned int uintptr_t;




typedef long long int intmax_t;
typedef long long unsigned int uintmax_t;
# 12 "/opt/riscv/lib/gcc/riscv32-unknown-elf/12.1.0/include/stdint.h" 2 3 4
# 5 "matmul.h" 2
# 1 "/opt/riscv/lib/gcc/riscv32-unknown-elf/12.1.0/include/stdbool.h" 1 3 4
# 6 "matmul.h" 2



 
# 9 "matmul.h"
int A[4*4] = {0, 1, 2, 3,
   0, 1, 2, 3,
   0, 1, 2, 3,
   0, 1, 2, 3,
 };
 int B[4*4] = {1, 2, 3, 4,
  5, 6, 7, 8,
  9, 10, 11, 12,
  13, 14, 15, 16,
 };
 int result[4*4];
# 2 "matmul.c" 2

int* __attribute__ ( ( section ( ".mprjram" ) ) ) matmul()
{
 int i;

 (*(volatile uint32_t*)0x30003000) = 1;

 for (i=0; i<4*4; i++){
  while(!(((*(volatile uint32_t*)0x30003000) >> 4) & 1));
  (*(volatile uint32_t*)0x30003080) = A[i];
 }
 for (i=0; i<4*4; i++){
  while(!(((*(volatile uint32_t*)0x30003000) >> 4) & 1));
  (*(volatile uint32_t*)0x30003080) = B[i];
 }
 for (i=0; i<4*4; i++){
  while(!(((*(volatile uint32_t*)0x30003000) >> 5) & 1));
  result[i] = (*(volatile uint32_t*)0x30003084);
 }

 return result;
}
