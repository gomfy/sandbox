#!/bin/bash

# Author(s): 	Gyorgy Matyasfalvi <matyasfalvi@ampl.com>, 
#		        Marcos Dominguez <marcos@ampl.com>,
#		        Filipe Brandao <fdabrandao@ampl.com>

#
# Description: 	Test script that creates pairs from an array of executables and
#		runs tests on them. The various tests are specified in an array.
#		A test instance comprises of comparing the outputs of the two 
#		different executables with cmp.
#		If the files are identical the test passes otherwise it fails.

# If debugging turn on -xve
#set -xve

# Set current directory
cd "`dirname "$0"`/../tests/"

# Define array of executables that will be tested
if [ "$#" -eq 0 ]; then
  exec_array=("origb-ax" "newb-ax")
else
  exec_array=( "$@" )
fi
num_exec=${#exec_array[@]}

# Define array of test cases 
# test cases are names of scripts that take the name of an ampl executable 
# as an input
test_array=("bug.cases" "test.cases" "crunch.cases" "tests_logic.cases" "tests_loop1.cases" "tests_loop2.cases" "tests_amplbook2.cases")
#test_array=("crunch.cases")
#test_array=(test-show.sh)
num_test=${#test_array[@]}

# Create a directory for test output files
if [ -d testout ];
then
	rm -r testout
	mkdir testout
else
	mkdir testout
fi

# Set return status to zero
stat=0

# Set pass, fail, total test, no test, and total attempt counter
ctpass=0
ctfail=0
cttottest=0
ctnot=0
cttotatte=0
printf "\n### START TESTING OUTPUTS ###\n\n"

# 1. Start testing
# Select pairs of ampl executables from exec_array and run each test on them
for (( i=0; i<$num_exec; i++ )); 
do
	for (( j=$i+1; j<$num_exec; j++ )); 
	do	
		ex1=${exec_array[$i]}
		ex2=${exec_array[$j]}	
		if [[ -x "$(command -v $ex1)" && -x "$(command -v $ex2)" ]]; 
		then
			# Run all the tests for those executables
			for (( t=0; t<$num_test; t++ ));
			do 
				f1="./testout/${test_array[$t]}.${ex1}"
				f2="./testout/${test_array[$t]}.${ex2}"
				# Lazy evaluation (it matters with > 2 executables)
				if [ ! -f $f1 ]; then
					./${test_array[$t]} $ex1 > $f1 2>&1 
				fi
				if [ ! -f $f2 ]; then
					./${test_array[$t]} $ex2 > $f2 2>&1
				fi
				# If outputs are the same, test passes, otherwise it fails
				if cmp -s $f1 $f2;
				then
					echo "PASSED TEST:  ${test_array[$t]} with ${ex1} and ${ex2} ..."
                    ((ctpass++))
				else
					echo "FAILED TEST:  ${test_array[$t]} with ${ex1} and ${ex2} ..."
                    ((ctfail++))
                    [ "$VERBOSE" ] && diff $f1 $f2
                    stat=134
				fi
			done
		else
			echo -e "NO TEST:      either ${ex1} or ${ex2} does not exist..."
            ((ctnot++)) 
		fi
	done
done
printf "\n### END TESTING OUTPUTS ###\n\n"

# 2. Summary of results
printf "\n### TEST SUMMARY ###\n\n"
cttottest=$((ctpass+ctfail))
cttotatte=$((cttottest+ctnot))
if (( cttottest == 0 ));
then
    echo -e "NO TESTS (CHECK EXECUTABLES AND SCRIPTS)\n"
elif (( ctfail > 0 )); 
then
    echo -e "$ctfail TESTS OUT OF $cttottest FAILED"
    echo -e "$ctnot NO TESTS OUT OF $cttotatte\n"
else
    echo -e "ALL $cttottest TESTS PASSED"
    echo -e "$ctnot NO TESTS OUT OF $cttotatte\n"
fi

[ "$VERBOSE" ] && grep "" -R testout

exit $stat
