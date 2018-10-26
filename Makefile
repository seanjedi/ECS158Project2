all: mmm_omp.c matrix_checksum.c
	gcc -Wall -Werror -fopenmp -pthread -O2 matrix_checksum.c mmm_omp.c -o mmm 
clean: 
	rm -f mmm
