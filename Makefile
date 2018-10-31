all: mmm_omp.c matrix_checksum.c
	gcc -Wall -Werror -O2 -fopenmp matrix_checksum.c mmm_omp.c -o mmm_omp
	gcc -Wall -Werror -O2 -fopenmp -lm matrix_checksum.c heat_distribution_serial.c -o heat_distribution_serial
	gcc -Wall -Werror -O2 -fopenmp -lm matrix_checksum.c heat_distribution_omp.c -o heat_distribution_omp

clean: 
	rm -f mmm_omp heat_distribution_serial heat_distribution_omp
