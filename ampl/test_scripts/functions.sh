#!/bin/bash

# Author(s):    Gyorgy Matyasfalvi <matyasfalvi@ampl.com>
#		        Marcos Dominguez <marcos@ampl.com>


# Description:  This script contains functions that are used 
#               in various other scripts: 
#               0. print_error
#               1. print_usage
#               2. arrange_args
#               3. parse_args
#               4. get_size
# TODO come up with more intuitive names for below
#               5. run_ampl_single
#               6. compare_nl
#               7. comparation_single 
#               8. run_ampl_pair
#               9. run_ampl_pair
# TODO come up with more intuitive names for above
#               10. get_md5

# Define return codes at the beginning
EXIT_SUCCESS=0
EXIT_FAILURE=134

#Function: print_error
print_error() {
        printf "ERROR in function '%s' at line %d." "${FUNCNAME[1]}" "${BASH_LINENO[0]}"
}


# Function: print_usage
# Print usage related information
# Input: 
#   N/A
# Sets variables:
#   N/A
print_usage() {
printf "\nUsage: $0 [-v] [-q #] EXEC1 EXEC2 ...\n"
printf "\t -v:           Verbose flag.\n"
printf "\t -x:           Nix-exit flag.\n"
printf "\t -q #:         Size threshold flag where # is an integer.\n"
printf "\t               If (max size / min size) > # size test fails.\n"
printf "\t EXEC1,EXEC2:  AMPL executables to be tested.\n"
printf "\t               Default: ampl and ax.\n"
printf "\t Note! At least two valid executables have to be specified\n"
printf "\t as tests are comparison based.\n"
}

# Function: arrange_args 
# rearragnes all options to place flags first
# this makes it possible to filter out executables 
# from command line options.
# Use before getops parsing in parse_args function. 
# Input: 
#   1. getopts style option string e.g. hv:d
#   2. calling script arguments e.g. "$@"
# Sets variables:
#   1. OPTARR
arrange_args() { 
    local flags 
    local args 
    # Get getopts style option string
    local optstr=$1
    shift

    # Loop through arguments and separate out valid options 
    # and their values from AMPL_EXEC-s
    while (($#)); do
        case $1 in
            --) args+=("$@")
                break;
                ;;
            -*) flags+=("$1")
                if [[ $optstr == *"${1: -1}:"* ]]; then
                    flags+=("$2")
                    shift
                fi
                ;;
            * ) args+=("$1")
                ;;
        esac
        shift
    done

    # Define variable that holds rearranged argumetns
    # options and values first then AMPL_EXEC-s
    OPTARR=("${flags[@]}" "${args[@]}")
}


# Function: parse_args
# Rearrange options by calling arrange_args
# then process options via getopts and store 
# executables and set option variables.
# Input: 
#   1. calling script arguments e.g. "$@"
# Sets variables:
#   1. EXEC_ARRAY
#   2. NUM_EXEC
parse_args() {
    local optstr=vxq:
    
    # Define: 
    # return codes, verbose mode, nix-exit mode,
    # array of executables, number of executables,
    # array of valid executables, number of valid executables,
    # array of no-test messages, number of no-test messages
    VERBOSE_MODE=false
    NIXEXIT_MODE=false
    EXEC_ARRAY=("ampl" "ax")
    NUM_EXEC=2
    VALID_EXEC_ARRAY=()
    NUM_VALID_EXEC=0
    NO_TEST_MESSAGE=()
    NUM_NO_TEST=0
    # Size threshold variable
    # for eeded for run_size_tests.sh script
    SIZE_THRESH=2
    # MD5 hash function to use
    MD5=sum

    arrange_args "$optstr" "$@"
    # turn off option processing for arguments
    # OPTARR is defined in arrange_args() 
    set -- "${OPTARR[@]}"
    
    # Process options
    OPTIND=1
    while getopts "$optstr" opt; do
        case $opt in
            v        ) VERBOSE_MODE=true ;; 
            x        ) NIXEXIT_MODE=true ;; 
            q        ) SIZE_THRESH=$OPTARG ;;
            \?       ) print_usage 
                       exit $EXIT_FAILURE ;;
        esac
    done
    shift $((OPTIND-1))
    
    # Define array of executables that will be tested
    # $@ is stripped of all valid options
    if [ "$#" -ne 0 ]; then
      EXEC_ARRAY=( "$@" )
    fi
    NUM_EXEC=${#EXEC_ARRAY[@]}

    # Check to make sure we have at least two executables
    if (( NUM_EXEC <= 1 ));
    then
        print_error
        print_usage
        exit $EXIT_FAILURE
    fi

    # Check if executables are in PATH  
    for (( i=0; i<$NUM_EXEC; i++ )); 
    do
    	ex=${EXEC_ARRAY[$i]}		
        if [[ -x "$(command -v $ex)" ]]; then
            VALID_EXEC_ARRAY+=($ex)
            ((NUM_VALID_EXEC++))
    	else
            if [ "$VERBOSE_MODE" = true ]; then
                NO_TEST_MESSAGE+=("NO TEST:    \t'${ex}' does not exist...\n")
            fi
            ((NUM_NO_TEST++))
    	fi
    done
    
    # Check to make sure we have at least two valid! executables
    if (( NUM_VALID_EXEC <= 1 ));
    then
        print_error
        print_usage
        exit $EXIT_FAILURE
    fi

    if ! [[ "$SIZE_THRESH" =~ ^[0-9]+$ ]]
    then
        print_error
        print_usage
        exit $EXIT_FAILURE
    fi
}


# Function: get_size
# 
# Input: 
#   1. variable $1 to hold values
#   2. variable $2 name of file
# Sets variables:
#   1. $1
get_size() {
    local -n siz_ref=$1
	# Check executable sizes
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        siz_ref=$(stat -c %s -- $(which "$2"))
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        siz_ref=$(stat -f %z -- $(which "$2"))  
    elif [[ "$OSTYPE" == "msys" ]]; then
        siz_ref=$(stat -c %s -- $(which "$2"))
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        siz_ref=$(stat -f %z -- $(which "$2"))  
    else
            print_error
            printf "MESSAGE: Unable to detect OS type...\n"
            exit $EXIT_FAILURE
    fi
}


# Function: 
# Include the script and write a nl file
function run_ampl_single {
	# -b4 => interactive mode!
	$2 -b4 > /dev/null 2>&1 <<!!!
	include $1;
	write g${output_dir}$1-$2;
	q;
!!!
}

# Function:
# Compare 2 nl files except the first line, as it is always different.
# A regular expression with diff is used for that.
# Usage: compare_nl file1 file2
function compare_nl {
	if [ ! -f "$1" ] || [ ! -f "$2" ]; then
		if [[ "$verbose_mode" = "true" ]]; then
			echo "NO TEST:  ${1#"$output_dir"} and ${2#"$output_dir"} $3  ..."
		fi
		return $EXIT_ERROR
	fi
	# all the nl files start with a line with this RE
	# '^g.*# problem .*$'
	if diff --ignore-matching-lines='^g.*# problem .*$' <(tail -n +1 $1) <(tail -n +1 $2) >/dev/null 2>&1;
	then
		if [[ "$verbose_mode" = "true" ]]; then
			echo "PASSED TEST:  ${1#"${output_dir}"} and ${2#"${output_dir}"} $3  ..."
		fi
		return $EXIT_SUCCESS
	fi
	echo "FAILED TEST:  ${1#"${output_dir}"} and ${2#"${output_dir}"} $3  ..."
	return $EXIT_FAILURE
}


# Function:
# Compare the nl files generated by one script or model file and 2 ampl versions.
# Each script is run, then the nl file is written.
# Usage: comparation_single script ampl1 ampl2
function comparation_single {
	f1="${output_dir}$1-$2.nl"
	f2="${output_dir}$1-$3.nl"
	
	compare_nl $f1 $f2
	e=$?

	if [ $e -eq $EXIT_SUCCESS ]; then
		((ok_tests++))
	elif [ $e -eq $EXIT_FAILURE ]; then
		((failed_tests++))
		stat=$EXIT_FAILURE
	elif [ $e -eq $EXIT_ERROR ]; then
		((no_tests++))
	fi

}


# Function:
# Write a .run script for ampl with the model and data file of a problem.
# Just reset, load model and data, write nl, solve, write nl again.
# Usage: run_ampl_pair modelname model data ampl
function run_ampl_pair {
	# -b4 => interactive mode!
	$4 -b4 > /dev/null 2>&1 <<!!!
	printf "# Artificial NL test for $1\n";
	option solver gurobi;
	reset;
	model $2;
	data $3;
	#printf "# Write .nl for $2 and $3 (before solving)\n";
	write g${output_dir}prev-$1-$4;
	#printf "# Solve $1 for $2 and $3\n";
	solve;
	#printf "# Write .nl for $1 and $2 (after solving)\n";
	write g${output_dir}post-$1-$4;
	q;
!!!
}


# Function:
# Compare a couple of nl files generated by some models and executables.
# Each model is paired with a data file, and then solved, so there are 2 nl files
# to check (before and after solving).
# Usage: comparation_pair modelname ampl1 ampl2
function comparation_pair {
	f1="${output_dir}prev-$1-$2.nl"
	f2="${output_dir}prev-$1-$3.nl"
	
	compare_nl $f1 $f2 "(before solving)"
	e=$?

	if [ $e -eq $EXIT_SUCCESS ]; then
		((ok_tests++))
	elif [ $e -eq $EXIT_FAILURE ]; then
		((failed_tests++))
		stat=$EXIT_FAILURE
	elif [ $e -eq $EXIT_ERROR ]; then
		((no_tests++))
	fi

	f1="${output_dir}post-$1-$2.nl"
	f2="${output_dir}post-$1-$3.nl"

	compare_nl $f1 $f2 "(after solving)"
	e=$?

	if [ $e -eq $EXIT_SUCCESS ]; then
		((ok_tests++))
	elif [ $e -eq $EXIT_FAILURE ]; then
		((failed_tests++))
		stat=$EXIT_FAILURE
	elif [ $e -eq $EXIT_ERROR ]; then
		((no_tests++))
	fi
}


# Function: get_md5
# determines which md5 command to call depending
# on the operating system
# Input: 
#   1. variable $1 to hold values
# Sets variables:
#   1. $1
get_md5() {
    local -n md5_ref=$1
	# Check executable sizes
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        md5_ref="md5sum"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        md5_ref="md5"  
    elif [[ "$OSTYPE" == "msys" ]]; then
        md5_ref="md5sum"
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        md5_ref="md5sum"
    else
            print_error
            printf "MESSAGE: Unable to detect OS type...\n"
            exit $EXIT_FAILURE
    fi
}
