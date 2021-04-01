#!/usr/bin/env bash

# Author(s): 	Gyorgy Matyasfalvi <matyasfalvi@ampl.com>, 
#
#
# Description: 	
# 

# If debugging turn on -xve
#set -xve

# Load user defined variables and functions
source ./functions.sh
STAT=$EXIT_SUCCESS
OUTPUT_MESSAGE=()
TIME_MESSAGE=()

# Parse arguments and set variables
parse_args "$@" 

# Check if output dir exists if no create it.
if [ ! -d "$TARGET_DIR" ]; then
    mkdir "$TARGET_DIR"
fi

# Set working directory
cd "$TARGET_DIR"

# Decide whether to message if _ampl_time or _solve_time is zero
msg_0_ampl_time="false"
msg_0_solve_time="false"


# Define array of directories that hold
# outputs of .cases scripts
dir_array=($(find . -type d -regextype posix-egrep -regex '.*(windows|macos|linux|dockcross).*'))
num_dir=${#dir_array[@]}


# Set pass, fail, and total test counter
num_passed_tests=0
num_failed_tests=0
num_total_tests=0


# 1. Start testing

if [ "$VERBOSE_MODE" = true ]; then
    printf "\n### START CASES TESTING (XPL)  ###\n"
    for i in "${NO_TEST_MESSAGE[@]}"
    do
        printf "$i"
    done
    if (( NUM_NO_TEST > 0)); then
        printf "\n"
    fi
else
    printf "\nRunning cases tests (xpl)...\n"
fi

# Determine the types of .cases by looking in the first available directory.
# Here we rely on the fact that every directory has to have the same .cases 
# tests i.e. we cannot have a situation where 
# dir_array[0] has bug.cases files but dir_array[1] doesn't.

dir=${dir_array[0]}
cases_array=($(ls $dir | awk -F. '{ print $1"."$2 }' | sort -u))
num_cases=${#cases_array[@]}

# Select pairs of directories from dir_array 
# and run each test on them. In this loop we rely on the
# fact that the `*.cases` script outputs follow the:
# $TARGET_DIR/${test_dir[$t]}/$RUN_CASES_TEST.$ex[12].$BUILD_METHOD.$os[12].$arch[12].{hash,time,raw}
# naming convention.

for (( i=0; i<$num_cases; i++ ));
do  
    ca=${cases_array[$i]}

    for (( j=0; j<$num_dir; j++ ));
    do 
        for (( k=$j+1; k<$num_dir; k++ ));
        do  
            # Define shorthands for various directories
            dir1=${dir_array[$j]}
            dir2=${dir_array[$k]}

            # Get the list of all .hash files for a particular .cases test
            hf1_array=($(find $dir1 -type f -regextype grep -regex ".*$ca.*\.hash"))
            hf2_array=($(find $dir2 -type f -regextype grep -regex ".*$ca.*\.hash"))

            # Select any .hash file as these have to be indentical
            # if it passed "in-platform" testing.
            # TODO exclude debug binaries e.g. `ax` so we can do timing tests
            hf1=${hf1_array[0]}
            hf2=${hf2_array[0]} 
           
            # Extract executable (ex) and build (b) info from file name
            info1=$(basename $hf1)
            info2=$(basename $hf2)
            info1=(${info1//\./ })
            info2=(${info2//\./ })
            ex1=${info1[2]}
            b1=${info1[3]}
            ex2=${info2[2]} 
            b2=${info2[3]}

            # Make sure that only results with the same arch 
            # (i.e. 64 vs 64 and 32 vs 32) are compared
            if [[ ($hf1 =~ "64" && $hf2 =~ "64") || ($hf1 =~ "32" && $hf2 =~ "32") ]]; then
                diffout=$(diff -y --suppress-common-lines $hf1 $hf2)
	        	if [ "$diffout" == "" ]; then
                    if [ "$VERBOSE_MODE" = true ]; then
                        printf "PASSED OUTPUT TEST:\t$ca with $ex1-$b1 and $ex2-$b2 ...\n"
                    fi
                    ((num_passed_tests++))
	        	else
                    if [ "$VERBOSE_MODE" = true ]; then
	        		    printf "FAILED OUTPUT TEST:\t$ca with $ex1-$b1 and $ex2-$b2 ...\n"
                        # Ensure that if there are missing tests for one of the
                        # executables (ex1 or ex2) the test id and tag gets printed
                        # (relies on diff output formatting) 
                        printf "$(printf "$diffout" | awk -F$'\t' '
                            { 
                                if ( $0 ~ /\|/ ) {
                                    print "                 \t"$1"\t"$2 
                                } else {
                                    print "                 \t"$9"\t"$10
                                }
                            }')\n"
	        	        rf1="${hf1/hash/raw}"
                   		rf2="${hf2/hash/raw}"
				        printf "          raw diff:\n"
                        diff -y --suppress-common-lines $rf1 $rf2 | awk '{ print "                   \t"$0 }'
                    fi
                    OUTPUT_MESSAGE+=("FAILED OUTPUT TEST:\t$ca with $ex1-$b1 and $ex2-$b2 ...\n")
                    OUTPUT_MESSAGE+=("$(printf "$diffout" | awk -F$'\t' '
                        { 
                            if ( $0 ~ /\|/ ) {
                                print "                 \t"$1"\t"$2 
                            } else {
                                print "                 \t"$9"\t"$10
                            }
                        }')\n")
                    ((num_failed_tests++))
                    STAT=$EXIT_FAILURE
	        	fi
            
                # Test speed of the executables 
                # If speed is below threshold, test passes, otherwise it fails
                # Initialize output status
                ampl_time_stat=0
                solve_time_stat=0
                # Exclude debug binaries from speed tests
                if [[ $ex1 != *$DEBUG_EXEC* && $ex2 != *$DEBUG_EXEC* ]]; then
                    # Set names of time files
    	        	tf1="${hf1/hash/time}"
                    tf2="${hf2/hash/time}"
                    # Adjust IFS so that awk return can be processed into an array 
                    defaultIFS=$IFS
                    IFS=$'\n'
                    # Use awk to compute ampl_time and solve_time ratios, 
                    # and store pass (0), fail (134) and associated message 
                    # in time_stat_message array
                    # Since below compares times individually, for every single test
                    # it is necessary to have the exact same number of "records" 
                    # in each file, in addition to ensuring that id-s match 
                    # when comparing records. Hence, fatal_error. 
                    # In addition since awk only has associative arrays in order
                    # to get the correct ordering of error messages we need to use
                    # FNR to index arrays 
                    time_stat_message=($(awk -v th=$SPEED_THRESH -v exec1="$ex1-$b1" -v exec2="$ex2-$b2" -v m0at=$msg_0_ampl_time -v m0st=$msg_0_solve_time ' 
                        function min(a, b) {
                            return a < b ? a : b
                        }
        
                        NR==FNR {  
                                    id1[FNR]=$1
                                    tag[FNR]=$2
                                    split($3,a,":") 
                                    split($4,s,":")
                                    at1[FNR]=a[2]
                                    st1[FNR]=s[2]
                                    fnr1=FNR
                                } 
                        NR>FNR  {   
                                    id2[FNR]=$1
                                    split($3,a,":")
                                    split($4,s,":")
                                    at2[FNR]=a[2]   
                                    st2[FNR]=s[2] 
                                    fnr2=FNR
                                } 
                        END     {   
                                    
                                    fatal_error=0
                                    stat_a=0
                                    stat_s=0
                                    num_msg=0
    
                                    if ( fnr1 != fnr2 ) {
                                            fatal_error=1
                                            printf("%d\n", fatal_error)
                                            printf("ERROR number of records in .time files are not equal (fnr1:%d != fnr2:%d)\n", fnr1, fnr2)
                                            exit
                                    }
    
                                    for ( i=1; i<=fnr1; i++ ) {
                                        if ( id1[i] != id2[i] ) {
                                            fatal_error=1
                                            printf("%d\n", fatal_error)
                                            printf("ERROR test id1 does not equal test id2 (%s != %s)\n", id1[i], id2[i])
                                            exit
                                        }
                                        a_l = min(at1[i],at2[i])
                                        if ( a_l < 0 ) { 
                                            fatal_error=1
                                            printf("%d\n", fatal_error)
                                            printf("ERROR _ampl_time is less than 0 (%f)\n", a_l)
                                            exit
                                        } else if ( a_l == 0) { 
                                            if ( ma0t == "true" ) {
                                                num_msg++
                                                msg[num_msg]=id1[i]" "tag[i]" _ampl_time is 0"
                                            }
                                        } else { 
                                            if ( at1[i] > at2[i] ) { 
                                                ra = at1[i]/at2[i]         
                                                if ( ra > th ) {
                                                    stat_a=134
                                                    sp=(ra-1)*100
                                                    num_msg++
                                                    msg[num_msg]=id1[i]" "tag[i]" _ampl_time with "exec2" is "sp" percent faster than "exec1
                                                }
                                            } else { 
                                                ra = at2[i]/at1[i]         
                                                if ( ra > th ) {
                                                    stat_a=134
                                                    sp=(ra-1)*100
                                                    num_msg++
                                                    msg[num_msg]=id1[i]" "tag[i]" _ampl_time with "exec1" is "sp" percent faster than "exec2
                                                }
                                            }
                                        }
                                        s_l = min(st1[i],st2[i]) 
                                        if ( s_l < 0 ) {
                                            fatal_error=1
                                            printf("%d\n", fatal_error)
                                            printf("ERROR _solve_time is less than 0 (%f)\n", s_l)
                                            exit
                                        } else if ( s_l == 0 ) { 
                                            if ( m0st == "true" ) {
                                                num_msg++
                                                msg[num_msg]=id1[i]" "tag[i]" _solve_time is 0"
                                            }
                                        } else {
                                            if ( st1[i] > st2[i] ) { 
                                                rs = st1[i]/st2[i]         
                                                if ( rs > th ) {
                                                    stat_s=134
                                                    sp=(rs-1)*100
                                                    num_msg++
                                                    msg[num_msg]=id1[i]" "tag[i]" _solve_time with "exec2" is "sp" percent faster than "exec1
                                                }
                                            } else { 
                                                rs = st2[i]/st1[i]         
                                                if ( rs > th ) {
                                                    stat_s=134
                                                    sp=(rs-1)*100
                                                    num_msg++
                                                    msg[num_msg]=id1[i]" "tag[i]" _solve_time with "exec1" is "sp" percent faster than "exec2
                                                }
                                            }
                                        }
                                    } 
                                    printf("%d\n", fatal_error)
                                    printf("%d\n", stat_a)
                                    printf("%d\n", stat_s)
                                    for ( j=1; j<=num_msg; j++ ) {
                                        printf("%s\n", msg[j])
                                    }
                                }' "$tf1" "$tf2"))
                            
                    # Process awk output
                    fatal_error=${time_stat_message[0]}
                    if (( fatal_error != 0 )); then
                        print_error
                        printf "\nINFO:\n"
                        printf "\t${time_stat_message[1]}\n"
                        
                        if [ "$VERBOSE_MODE" != true ]; then
                            for i in "${OUTPUT_MESSAGE[@]}"
                            do
                                printf "$i"
                            done
                            for i in "${TIME_MESSAGE[@]}"
                            do
                                printf "$i"
                            done
                        fi
                    exit $EXIT_FAILURE
                    fi
                    ampl_time_stat=${time_stat_message[1]}               
                    solve_time_stat=${time_stat_message[2]}
                    time_message=( "${time_stat_message[@]:3}" )
    
                    # Print results and adjust counter
                    if (( ampl_time_stat == 0 && solve_time_stat == 0 )); then
                        if [ "$VERBOSE_MODE" = true ]; then
        		    	    printf "PASSED SPEED TEST:\t$ca with $ex1-$b1 and $ex2-$b2 ...\n"
                        fi
                        ((num_passed_tests++)) 
        		    else
                        if [ "$VERBOSE_MODE" = true ]; then
        		            printf "FAILED SPEED TEST:\t$ca with $ex1-$b1 and $ex2-$b2 ...\n"
                            for l in "${time_message[@]}"
                            do
                                printf "                  \t$l\n"
                            done
                        else
                            TIME_MESSAGE+=("FAILED SPEED TEST:\t$ca with $ex1-$b1 and $ex2-$b2 ...\n")
                            for l in "${time_message[@]}"
                            do
                                TIME_MESSAGE+=("                  \t$l\n")
                            done
                        fi
                        ((num_failed_tests++))
                        STAT=$EXIT_FAILURE
                    fi
    
                    # Change IFS back to default 
                    IFS=$defaultIFS 
                fi
            fi
        done
    done
done


# 2. Display summary of results
num_total_tests=$((num_passed_tests+num_failed_tests))
if [ "$VERBOSE_MODE" = true ]; then
    printf "# TEST SUMMARY\n"
    if (( STAT == EXIT_FAILURE )); then
        printf "$num_failed_tests TESTS OUT OF $num_total_tests FAILED\n"
    else
        printf "ALL $num_total_tests TESTS PASSED\n"
    fi
    printf "### END CASES TESTING (XPL) ###\n"
else
    if (( STAT == EXIT_FAILURE )); then 
        printf "$num_failed_tests tests out of $num_total_tests failed:\n"
        for i in "${OUTPUT_MESSAGE[@]}"
        do
            printf "$i"
        done
        for i in "${TIME_MESSAGE[@]}"
        do
            printf "$i"
        done
    else
        printf "All tests passed!\n"
    fi
    printf "\n"
fi


# If nix-exit mode is not truned on call exit
if [ "$NIXEXIT_MODE" = false ]; then
    exit $STAT
fi
