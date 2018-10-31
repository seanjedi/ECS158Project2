#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<math.h>
#include<time.h>
#include<omp.h>

unsigned int matrix_checksum(int, double*);
#define thread_count 4

#define max(a,b) (((a) > (b)) ? (a) : (b)) 

/////////////////
//Main Function//
/////////////////
int main(int argc, char **argv)
{
	//////////////////
	//Get User Input//
	//////////////////
	if(argc != 5){//if wrong number of inputs
		fprintf(stderr, "Usage: ./heat_distribution_serial N fire_temp wall_temp epsilon\n");
		exit(1);
	}

	int N;
	double north, walls, epsilon;

	if(!(N = atoi(argv[1])) || N < 3 || N > 2000){
                printf("Error: wrong map order (3 <= N <= 2000)\n");
                exit(1);
	}
	north = atof(argv[2]);
	if(north < 0.0f || north > 100.0f){
                printf("Error: wrong north temperature (0 <= N <= 100)\n");
                exit(1);
	}
    walls = atof(argv[3]);
	if(walls < 0.0f || walls > 100.0f){
                printf("Error: wrong walls temperature (0 <= N <= 100)\n");
                exit(1);
	}
	epsilon = atof(argv[4]);
	if(epsilon <  0.000001f || epsilon > 100.0f){
                printf("Error: wrong epsilon value (1e-6 <= N <= 100)\n");
                exit(1);
	}
	
	////////////////////////////
	//Initialize Heat matrixes//
	////////////////////////////
    // double heat[2][N*N];

	double* heat[2];
	heat[0] = malloc(N * N * sizeof(double));
	heat[1] = malloc(N * N * sizeof(double));

    struct timespec before, after;

    clock_gettime(CLOCK_MONOTONIC, &before);
    //Calculate Average
    double average = ((walls * (3 * N - 4)) + (north * N))/(4*N-4);
    #pragma omp parallel num_threads(thread_count)
    {
        //Heat map inialization walls
        #pragma omp for schedule(auto)
        for(int i = 0; i < N ; i++){
            heat[0][i*N] = walls;
            heat[0][(i*N) + N] = walls;
            heat[0][i + N] = walls;
            heat[0][i] = north;

            heat[1][i*N] = walls;
            heat[1][(i*N) + N] = walls;
            heat[1][i + N] = walls;
            heat[1][i] = north;
        }

        //Heat map inialization inner
        #pragma omp for schedule(auto)
        for(int i = 1; i < N -1; i ++){
            for(int j = 1; j < N -1; j++){
                heat[0][i * N + j] = average;
                heat[1][i * N + j] = average;
            }
        }
    }
    clock_gettime(CLOCK_MONOTONIC, &after);
	//Initialization done!

    unsigned long elapsed_ns = (after.tv_sec - before.tv_sec)*(1E9) + after.tv_nsec - before.tv_nsec;
	double seconds = elapsed_ns / (1E9);

	printf("Running time: %f secs\n", seconds);
	printf("mean: %f\n", average);
	printf("hmap: %u\n", matrix_checksum(N, heat[0]));

	////////////////////
	//Heatmap function//
	////////////////////
    int curr = 0, next = 1, print = 1, iteration = 1;
	double differences = 101;
	clock_gettime(CLOCK_MONOTONIC, &before);
    while(differences > epsilon){
		differences = 0;
        #pragma omp parallel num_threads(thread_count)
        #pragma omp for schedule(auto) reduction(max:differences)
        for(int i = 1; i < N - 1; i++){
            for(int j = 1; j < N -1; j++){
                heat[next][i * N + j] = (heat[curr][(i-1) * N + j] + heat[curr][(i+1) * N + j] + heat[curr][i * N + (j-1)] + heat[curr][i * N + (j+1)]) / 4;
				double generation_gap = fabs(heat[next][i*N + j] - heat[curr][i*N + j]);
				differences = max(differences, generation_gap);
            }
        }
		
		if(iteration == print){
			printf("%d\t%f\n", iteration, differences);
			print *= 2;
		}

		iteration++;
        curr = next;
        next = (curr + 1) % 2;
    }
	
	clock_gettime(CLOCK_MONOTONIC, &after);
	printf("%d\t%f\n", --iteration, differences);

	elapsed_ns = (after.tv_sec - before.tv_sec)*(1E9) + after.tv_nsec - before.tv_nsec;
	seconds = elapsed_ns / (1E9);

	printf("Running time: %f secs\n", seconds);
    printf("hmap: %u\n", matrix_checksum(N, heat[curr]));
	free(heat[0]);
	free(heat[1]);
	
	return 0;
}
