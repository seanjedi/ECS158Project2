#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<time.h>

unsigned int matrix_checksum(int, double*);

/////////////////
//Main Function//
/////////////////
int main(int argc, char **argv)
{
	if(argc != 5){//if wrong number of inputs
		fprintf(stderr, "Usage: ./heat_distribution_serial N fire_temp wall_temp epsilon");
		exit(1);
	}

	int N, north, walls, epsilon;

	if(!(N = atoi(argv[2]))){
		printf("Error: wrong map order (1 < N <= 2000)\n");
		exit(1);
	}
	if(N <= 0 || N > 2000){
                printf("Error: wrong map order (0 < N <= 2000)\n");
                exit(1);
	}
    if(!(north = atoi(argv[3]))){
		printf("Error: wrong north temperature (0 < N <= 100)\n");
		exit(1);
	}
	if(north <= 0 || north > 100){
                printf("Error: wrong north temperature (0 < N <= 100)\n");
                exit(1);
	}
       if(!(walls = atoi(argv[4]))){
		printf("Error: wrong walls temperature (0 < N <= 100)\n");
		exit(1);
	}
	if(wals <= 0 || walls > 100){
                printf("Error: wrong walls temperature (0 < N <= 100)\n");
                exit(1);
	}
       if(!(epsilon = atoi(argv[5]))){
		printf("Error: wrong epsilon value (0 < N <= 100)\n");
		exit(1);
	}
	if(north <= 1e-6 || north > 100){
                printf("Error: wrong epsilon value (1e-6 < N <= 100)\n");
                exit(1);
	}

    double heat[2][N*N];
    struct timespec before, after;

    clock_gettime(CLOCK_MONOTONIC, &before);
    //Heat map inialization walls
	for(int i = N - 1; i > 0; i--){
		heat[0][i*N] = walls;
        heat[0][(i*N) + N] = walls;
        heat[0][i] = walls;
	}

    //Heat map inialization north
	for(int i = N; i > 0; i--){
		heat[0][i+N] = north;
	}
    //Calculate Average
    double average = (walls * (3 * N - 2)) + (north * N);
    //Heat map inialization inner
    for(int i = 1; i < N -1; i ++){
        for(int j = 1; j < N -1; j++){
            heat[0][i * N + j] = average;
        }
    }
    clock_gettime(CLOCK_MONOTONIC, &after);
    unsigned long elapsed_ns = (after.tv_sec - before.tv_sec)*(1E9) + after.tv_nsec - before.tv_nsec;
	double seconds = elapsed_ns / (1E9);

	printf("Running time: %f secs\n", seconds);


    int curr = 0, next = 0;
    double difference;
	

	clock_gettime(CLOCK_MONOTONIC, &before);
    while(difference > epsilon){
        for(int i = 1; i < N -1; i ++){
            for(int j = 1; j < N -1; j++){
                heat[next][i * N + j] = (heat[curr][(i-1) * N + j] + heat[curr][(i+1) *N + j] + heat[curr][i * N + (j-1)] + h[curr][i * N (j+1)]) / 4;
            }
        }
        curr = next;
        next = (curr + 1) % 2;
    }
	
	clock_gettime(CLOCK_MONOTONIC, &after);

	unsigned long elapsed_ns = (after.tv_sec - before.tv_sec)*(1E9) + after.tv_nsec - before.tv_nsec;
	double seconds = elapsed_ns / (1E9);

	printf("Running time: %f secs\n", seconds);
	
	return 0;
}
