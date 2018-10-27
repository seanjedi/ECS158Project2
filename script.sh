#!/bin/bash

NUMBERS="1 2 4 8 16 32"

for i in `echo $NUMBERS` 
do
	OMP_NUM_THREADS=$i ./mmm_omp 2000
done

