#!/bin/bash

ORDERS="50 200 500 1000 2000"
NUMBERS="1 2 4 8 16 32"

for i in `echo $ORDERS`
do
	echo -e "\033[36mPthread\033[m $i"
	../P1/mmm pthread $i | grep 'Running time'
	echo -e "\033[31mOMP\033[m $i"
	./mmm_omp $i | grep 'Running time'

done


for i in `echo $NUMBERS` 
do
	echo "Threads: $i"
	OMP_NUM_THREADS=$i ./mmm_omp 2000 | grep 'Running time'
done

