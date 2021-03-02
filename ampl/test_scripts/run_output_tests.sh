#!/bin/bash

# Author(s): 	Gyorgy Matyasfalvi <matyasfalvi@ampl.com>, 
#		        Marcos Dominguez <marcos@ampl.com>,
#		        Filipe Brandao <fdabrandao@ampl.com>
#
#
# Description: 	Test script that creates pairs from an array of executables and
#		runs tests on them. The various tests are specified in an array.
#		A test instance comprises of comparing the outputs of the two 
#		different executables with cmp.
#		If the files are identical the test passes otherwise it fails.

# If debugging turn on -xve
#set -xve

# Load user defined variables and functions
source ./functions.sh
OUTPUT_STAT=$EXIT_SUCCESS
OUTPUT_ERROR_MESSAGE=()

# Set working directory
#cd "$(dirname $0)/../tests/"

# Parse arguments and set variables
parse_args "$@" 

# Define array of test cases 
# test cases are names of scripts that take the name of an ampl executable 
# as an input
test_array=("bug.cases")
num_test=${#test_array[@]}

# Check if OUTPUT_DIR exists if yes delete it and recreate it
if [ -d $OUTPUT_DIR ];then
	rm -r $OUTPUT_DIR
fi
mkdir $OUTPUT_DIR

# Set pass, fail, and total test counter
num_passed_tests=0
num_failed_tests=0
num_tests=0


# 1. Start testing

if [ "$VERBOSE_MODE" = true ]; then
    printf "\n### START TESTING OUTPUTS ###\n"
    for i in "${NO_TEST_MESSAGE[@]}"
    do
        printf "$i"
    done
    if (( NUM_NO_TEST > 0)); then
        printf "\n"
    fi
else
    printf "\nRunning output tests...\n"
fi

# Select pairs of ampl executables from VALID_EXEC_ARRAY 
# and run each test on them. In this loop we rely on the
# fact that the `*.cases` script follow the:
# ./$OUTPUT_DIR/${test_array[$t]}.${ex1}.{hash,time}
# naming convention
for (( i=0; i<$NUM_VALID_EXEC; i++ )); 
do
	for (( j=$i+1; j<$NUM_VALID_EXEC; j++ )); 
	do	
		ex1=${VALID_EXEC_ARRAY[$i]}
		ex2=${VALID_EXEC_ARRAY[$j]}	
		# Run all the tests for those executables
		for (( t=0; t<$num_test; t++ ));
		do 
			hf1="./$OUTPUT_DIR/${test_array[$t]}.${ex1}.hash"
			hf2="./$OUTPUT_DIR/${test_array[$t]}.${ex2}.hash"
			# Lazy evaluation (it matters with > 2 executables)
			if [ ! -f $hf1 ]; then
				./${test_array[$t]} $ex1 2>&1 
			fi
			if [ ! -f $hf2 ]; then
				./${test_array[$t]} $ex2 2>&1
			fi
			
            # Test each output run against others
            # If outputs are the same, test passes, otherwise it fails
            diffout=$(diff -y --suppress-common-lines $hf1 $hf2)
			if [ "$diffout" == "" ]; then
                if [ "$VERBOSE_MODE" = true ]; then
				    printf "PASSED TEST:\t${test_array[$t]} with ${ex1} and ${ex2} ...\n"
                fi
                ((num_passed_tests++))
			else
                if [ "$VERBOSE_MODE" = true ]; then
				    printf "FAILED TEST:\t${test_array[$t]} with ${ex1} and ${ex2} ...\n"
                    printf "$(printf "$diffout" | awk -F$'\t' '{ print "            \t"$1"\t"$2 }')\n"
                fi
                OUTPUT_ERROR_MESSAGE+=("FAILED TEST:\t${test_array[$t]} with ${ex1} and ${ex2} ...\n")
                OUTPUT_ERROR_MESSAGE+=("$(printf "$diffout" | awk -F$'\t' '{ print "            \t"$1"\t"$2 }')\n")
                ((num_failed_tests++))
                OUTPUT_STAT=$EXIT_FAILURE
			fi

			# For non-debug binaries check speed
            # If speed is below threshold, test passes, otherwise it fails
			if [[ $hf1 =~ .*$DEBUG_EXEC.* || $hf2 =~ .*$DEBUG_EXEC.* ]]; then
    			tf1="./$OUTPUT_DIR/${test_array[$t]}.${ex1}.time"
    			tf2="./$OUTPUT_DIR/${test_array[$t]}.${ex2}.time"
                # Use awk to compute ampl_time and solve_time ratios, 
                # and store pass (0) and fail (134) in TIME_STAT array
                TIME_STAT=($(awk -v th=$SPEED_THRESH '
                    function max(a, b) {
                        return a > b ? a : b
                    }
                    
                    function min(a, b) {
                        return a < b ? a : b
                    }

                    NR==FNR {   
                                split($3,a,":"); 
                                split($4,s,":"); 
                                at1+=a[2]; 
                                st1+=s[2]; next 
                            } 
                            {   
                                split($3,a,":");
                                split($4,s,":");
                                at2+=a[2];     
                                st2+=s[2] 
                            } 
                    END     {   
                                stat_a=0
                                stat_s=0
                                a_l = min(at1,at2)
                                a_h = max(at1,at2)
                                if ( a_l > 0 ) { 
                                    ra = a_h/a_l         
                                    if ( ra > th ) {
                                        stat_a=134
                                    }
                                } else {
                                    printf("ERROR minimum ampl running time is %f", a_l)
                                    exit
                                }
                                s_l = min(st1,st2) 
                                s_h = max(st1,st2)
                                if ( s_l > 0 ) {
                                    rs = s_h/s_l
                                    if ( rs > th ) {
                                        stat_s=134
                                    }
                                } else {
                                    rs = 0
                                }
                                printf("%d %d", stat_a,stat_s)
                            }' "$tf1" "$tf2"))
                echo "${TIME_STAT[@]}"
                exit 0

#                if [ "$VERBOSE_MODE" = true ]; then
#				    printf "PASSED TEST:\t${test_array[$t]} with ${ex1} and ${ex2} ...\n"
#                fi
#                ((num_passed_tests++))
#			else
#                if [ "$VERBOSE_MODE" = true ]; then
#				    printf "FAILED TEST:\t${test_array[$t]} with ${ex1} and ${ex2} ...\n"
#                    printf "$(printf "$diffout" | awk -F$'\t' '{ print "            \t"$1"\t"$2 }')\n"
#                fi
#                OUTPUT_ERROR_MESSAGE+=("FAILED TEST:\t${test_array[$t]} with ${ex1} and ${ex2} ...\n")
#                OUTPUT_ERROR_MESSAGE+=("$(printf "$diffout" | awk -F$'\t' '{ print "            \t"$1"\t"$2 }')\n")
#                ((num_failed_tests++))
#                OUTPUT_STAT=$EXIT_FAILURE
            fi
		done
	done
done

# 2. Display summary of results
num_tests=$((num_passed_tests+num_failed_tests))
if [ "$VERBOSE_MODE" = true ]; then
    printf "# TEST SUMMARY\n"
    if (( OUTPUT_STAT == EXIT_FAILURE )); then
        printf "$num_failed_tests TESTS OUT OF $num_tests FAILED\n"
    else
        printf "ALL $num_tests TESTS PASSED\n"
    fi
    printf "### END TESTING OUTPUTS ###\n"
else
    if (( OUTPUT_STAT == EXIT_FAILURE )); then 
        printf "$num_failed_tests tests out of $num_tests failed:\n"
        for i in "${OUTPUT_ERROR_MESSAGE[@]}"
        do
            printf "$i"
        done
    else
        printf "All tests passed!\n"
    fi
    printf "\n"
fi

# Clean generated testout directory with -r flag
if [ "$REMOVE_FLAG" = "true" ]; then
	rm -r testout
fi

# If nix-exit mode is not truned on call exit
if [ "$NIXEXIT_MODE" = false ]; then
    exit $OUTPUT_STAT
fi
