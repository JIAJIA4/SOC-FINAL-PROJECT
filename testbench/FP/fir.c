#include "fir.h"
#include "defs.h"

void __attribute__ ( ( section ( ".mprjram" ) ) ) initfir() {
	//initial your fir
	for(int i = 0; i < 64; i++){
		outputsignal[i] = 0;
	}

	tap0 = 0;
	tap1 = -10;
	tap2 = -9;
	tap3 = 23;
	tap4 = 56;
	tap5 = 63;
	tap6 = 56;
	tap7 = 23;
	tap8 = -9;
	tap9 = -10;
	tap10 = 0;

	data_len = 64;
}

int* __attribute__ ( ( section ( ".mprjram" ) ) ) fir(){

	int ans;
	AP = 1; // AP Start

	initfir();

	for(int i = 0; i < 64; i++){
		while(!((AP >> 4) & 1))	// Check X is ready to accept
			;

		X = i;

		while(!((AP >> 5) & 1))	// Check Y is ready to read
			;

		outputsignal[i] = Y;
	}

	return outputsignal; 
}
		
