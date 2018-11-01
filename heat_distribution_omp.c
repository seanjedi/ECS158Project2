#include<stdio.h>
#include<stdlib.h>
#include<time.h>
#include<math.h>

unsigned int matrix_checksum(int, double*);

int run(double* room[2], int N, double epsilon){
	int iteration = 0;
	int c = 0, n = 1; // current and next
	double maxdiff = 101;
	int print_ind = 1;
	while(maxdiff > epsilon){
		maxdiff = 0;
		#pragma omp parallel for reduction(max:maxdiff)
		for(int i = 1; i < N - 1; i++){
			for(int j = 1; j < N - 1; j++){
				room[n][i*N + j] = (room[c][(i-1)*N + j] + room[c][(i+1)*N + j] + room[c][i*N + j - 1] + room[c][i*N + j + 1])/4; // average
				double t = fabs(room[n][i*N + j] - room[c][i*N + j]);
				if(maxdiff < t)
					maxdiff = t;
			}
		}
		c = !c;
		n = !n;
		if(iteration == print_ind - 1){
			print_ind *= 2;
			printf("%-7d %f\n", iteration + 1, maxdiff);
		}
		if(maxdiff <= epsilon){
			printf("%-7d %f\n", iteration + 1, maxdiff);
			return c; // last updated matrix
		}
		iteration++;
	}
	return c; // last updated matrix

}

int main(int argc, char **argv)
{
        if(argc != 5){
                fprintf(stderr, "Usage: %s N fire_temp wall_temp epsilon\n", *argv);
                exit(1);
        }

        int N;
        double fire_temp, wall_temp, epsilon;

        if(!(N = atoi(argv[1])) || N < 3 || N > 2000){
		fprintf(stderr, "Error: wrong map order (3 <= N <= 2000)\n");
		exit(1);
	}

	fire_temp = atof(argv[2]);
	if(fire_temp < 0.0f || fire_temp > 100.0f){
		fprintf(stderr, "Error: wrong fire temperature (%f <= N <= %f)\n", 0.0f, 100.0f);
		exit(1);
	}

	wall_temp = atof(argv[3]);
	if(wall_temp < 0.0f || wall_temp > 100.0f){
                fprintf(stderr, "Error: wrong wall temperature (%f <= N <= %f)\n", 0.0f, 100.0f);
		exit(1);
        }

	epsilon = atof(argv[4]);
	if(epsilon < 0.000001f || epsilon > 100.0f){
                fprintf(stderr, "Error: wrong epsilon (%f <= N <= %f)\n", 0.000001f, 100.0f);
		exit(1);
        }
	// end of input validation

        struct timespec before, after;
        clock_gettime(CLOCK_MONOTONIC, &before);
	
	double average = 0;
	double* room[2];
	room[0] = malloc(N * N * sizeof(double));
	room[1] = malloc(N * N * sizeof(double));
	double total = 0;

	#pragma omp parallel reduction(+:total)
	{
		#pragma omp master
		{
			room[0][0] = fire_temp;
                        room[1][0] = fire_temp;
			total += fire_temp;
		}
		#pragma omp for
		for(int j = 1; j < N; j++){ // walls
			room[0][j] = fire_temp;
                        room[1][j] = fire_temp;
			room[0][j*N] = room[0][j*N + N - 1] = room[0][N*(N-1) + j] = wall_temp;
			room[1][j*N] = room[1][j*N + N - 1] = room[1][N*(N-1) + j] = wall_temp;
			total += fire_temp + wall_temp * (2 + (j != N - 1));
		}
	}

	average = total/(4 * N - 4);
	
	#pragma omp parallel for
	for(int i = 1; i < N - 1; i++){ // middle
		for(int j = 1; j < N - 1; j++){
			room[0][i + j*N] = average;
		}
		for(int j = 1; j < N - 1; j++){
                        room[1][i + j*N] = average;
                }
	}
	
	clock_gettime(CLOCK_MONOTONIC, &after);
        unsigned long elapsed_ns = (after.tv_sec - before.tv_sec)*(1E9) + after.tv_nsec - before.tv_nsec;
        double seconds = elapsed_ns / (1E9);
 	printf("Running time: %f secs\n", seconds);
	printf("mean: %f\n", average);
	printf("hmap: %u\n", matrix_checksum(N, room[0]));
	// end of initialization


        clock_gettime(CLOCK_MONOTONIC, &before);
	
	int which_matrix = run(room, N, epsilon);

        clock_gettime(CLOCK_MONOTONIC, &after);
        elapsed_ns = (after.tv_sec - before.tv_sec)*(1E9) + after.tv_nsec - before.tv_nsec;
        seconds = elapsed_ns / (1E9);
        printf("Running time: %f secs\n", seconds);
        printf("hmap: %u\n", matrix_checksum(N, room[which_matrix]));



	free(room[0]);
	free(room[1]);
}
