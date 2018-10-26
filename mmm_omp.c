#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<time.h>
#include<omp.h>

unsigned int matrix_checksum(int, double*);

/////////////////////
//Multiply Function//
/////////////////////
void multiply_omp(double* A, double* B, double* C, int N){
	#pragma omp for schedule(auto)
	for(int i = 0; i < N; i++){
		for(int j = 0; j < N; j++){
			for(int k = 0; k < N; k++){
				C[i*N + j] += A[i*N + k] * B[k*N + j];
			}
		}
	}
	return;
}

int main(int argc, char **argv)
{
	if(argc != 2){//if wrong number of inputs
		fprintf(stderr, "Usage: %s N\n", *argv);
		exit(1);
	}

	int N;

	if(!(N = atoi(argv[2]))){
		printf("Error: wrong matrix order (0 < N <= 2000)\n");
		exit(1);
	}
	if(N <= 0 || N > 2000){
                printf("Error: wrong matrix order (0 < N <= 2000)\n");
                exit(1);
	}

	double* A = malloc(sizeof(double) * N * N);
	double* B = malloc(sizeof(double) * N * N);
	double* C = malloc(sizeof(double) * N * N);
	for(int i = 0; i < N * N; i++){ // Matrix initialization
		A[i] = i/N + i%N;
		B[i] = i/N + (i%N)*2;
	}

	struct timespec before, after;

	clock_gettime(CLOCK_MONOTONIC, &before);
	#pragma omp parallel
	multiply_omp(A, B, C, N);
	clock_gettime(CLOCK_MONOTONIC, &after);

	unsigned long elapsed_ns = (after.tv_sec - before.tv_sec)*(1E9) + after.tv_nsec - before.tv_nsec;
	double seconds = elapsed_ns / (1E9);

	printf("Running time: %f secs\n", seconds);

	printf("A: %u\n", matrix_checksum(N, A));
	printf("B: %u\n", matrix_checksum(N, B));
    	printf("C: %u\n", matrix_checksum(N, C));

    	free(A);
    	free(B);
    	free(C);	
	
	return 0;
}
