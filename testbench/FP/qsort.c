#include "qsort.h"
#include "defs.h"

int* __attribute__ ( ( section ( ".mprjram" ) ) ) qsort(){

	int ans;
	AP = 1; // AP Start
	
	for(int i = 0; i < 10; i++){
		while(!((AP >> 4) & 1)); // Check X is ready to accept
		X = Q[i];
	}
	
	for(int i = 0; i < 10; i++){
		while(!((AP >> 5) & 1)); // Check Y is ready to read
		
		Q[i] = Y;	
	}
	
	

	return Q;
}