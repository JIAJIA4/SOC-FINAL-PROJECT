#include "matmul.h"

int* __attribute__ ( ( section ( ".mprjram" ) ) ) matmul()
{
	int i;
	
	AP = 1;
	
	for (i=0; i<SIZE*SIZE; i++){
		while(!((AP >> 4) & 1)); // Check A is ready to accept
		X = A[i];
	}
	for (i=0; i<SIZE*SIZE; i++){
		while(!((AP >> 4) & 1)); // Check B is ready to accept
		X = B[i];
	}
	for (i=0; i<SIZE*SIZE; i++){
		while(!((AP >> 5) & 1)); // Check Y is ready to read
		result[i] = Y;
	}
	
	return result;
}