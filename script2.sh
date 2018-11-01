#!/bin/bash

PROGRAMS="heat_distribution_serial heat_distribution_omp"
SER="heat_distribution_serial"
OMP="heat_distribution_omp"
ORDERS="50 200 500 1000 2000"
SER_ORDERS="50 200 500"
THREADS="1 2 4 8 16 32"
THREAD_HEADER=",1,2,4,8,16,32"
SER_THREADS="1"
SER_THREAD_HEADER=",1"
EPSILONS="0.001 0.01 0.1 100"

for prog in `echo $SER`
do
	echo "$prog"
	for eps in `echo $EPSILONS`
	do
		echo "Epsilon $eps"
		echo "$SER_THREAD_HEADER"

		for ord in `echo $SER_ORDERS`
		do
			printf "$ord,"
			for t in `echo $SER_THREADS`
			do

				printf "$(OMP_NUM_THREADS=$t $prog $ord 100 0 $eps | grep 'Running'  | grep -o -E [0-9]+.[0-9]+),"
			done
			echo
		done
	done
done

echo

for prog in `echo $OMP`
do
        echo "$prog"
        for eps in `echo $EPSILONS`
        do
                echo "Epsilon $eps"
                echo "$THREAD_HEADER"

                for ord in `echo $ORDERS`
                do
                        printf "$ord,"
                        for t in `echo $THREADS`
                        do

                                printf "$(OMP_NUM_THREADS=$t $prog $ord 100 0 $eps | grep 'Running'  | grep -o -E [0-9]+.[0-9]+),"
                        done
                        echo
                done
        done
done
