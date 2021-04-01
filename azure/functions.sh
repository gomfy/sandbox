#!/usr/bin/env bash

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
#               5. run_ampl_script
#               6. run_model_data
#               7. compare_nl_files
# TODO come up with more intuitive names for above
#              8. get_md5
#              9. get_host_os
#              10. get_target_os
#              11. get_target_arch
#              12. get_sed

# Define return codes at the beginning
EXIT_SUCCESS=0
EXIT_FAILURE=134

#Function: print_error
print_error() {
        printf "ERROR:\n" 
        printf "\tfile:     \t%s\n" "$(basename $0)"
        printf "\tfunction: \t%s\n" "${FUNCNAME[1]}"
        printf "\tline:     \t%d\n" "${BASH_LINENO[0]}"
}


# TODO  clean up options (e.g. no need for -x) 
#       add more info (e.g. description but also default options.)
# Function: print_usage
# Print usage related information
# Input: 
#   N/A
# Sets variables:
#   N/A
print_usage() {
printf "\nUSAGE:\n"
printf "\t $(basename $0) [-c] [-d] [-e] [-o] [-q] [-r] [-t] [-v] [-x] EXEC1 EXEC2 ...\n"
printf "\t -c:           Specify which .cases file to run (default: all).\n"
printf "\t -d:           .\n"
printf "\t -e:           .\n"
printf "\t -g:           Specify debug executable (default: ax).\n"
printf "\t -o:           Output directory.\n"
printf "\t -q #:         Size threshold flag where # is an integer.\n"
printf "\t               If (max size / min size) > # size test fails.\n"
printf "\t -r:           .\n"
printf "\t -t:           Specify which test_id within a cases file to run (default: all).\n"
printf "\t -s #:         Speed threshold flag where # is a number.\n"
printf "\t               If (max speed / min speed) > # speed test fails.\n"
printf "\t -v:           Verbose flag.\n"
printf "\t -x:           Nix-exit flag.\n"
printf "\t EXEC1,EXEC2:  AMPL executables to be tested.\n"
printf "\t               Default: ampl and ax.\n"
printf "\nINFO:\n"
printf "\tFor 'run_*' tests at least two valid executables have to be specified\n"
printf "\tFor '*.cases' tests at least one valid executable has to specified.\n"
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

    # Define variable that holds rearranged arguments
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
# TODO organize and finish this list
#   1. EXEC_ARRAY
#   2. NUM_EXEC
parse_args() {
    local optstr=b:c:d:e:g:o:q:rs:t:vx
  
    # TODO based on above rewrite below 
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
    DEBUG_EXEC="ax"
    NUM_VALID_EXEC=0
    NO_TEST_MESSAGE=()
    NUM_NO_TEST=0
    # Size threshold variable
    # needed for run_size_tests.sh script
    SIZE_THRESH=3 # TODO modify this to also allow for floating point
    # Speed thershold variable
    # need for run_output_tests.sh script
    SPEED_THRESH=1.1
    # For nl testing
    TARGET_DIR='.'
    OUTPUT_DIR="testout"
    OUTPUT_DIR_NL="${OUTPUT_DIR}/nl/"
    REMOVE_FLAG=false
    FILE_EXPRESSION=".run"
    RUN_TEST_ID="all"
    RUN_TEST_CASES="all"
    BUILD_METHOD="na"

    arrange_args "$optstr" "$@"
    # turn off option processing for arguments
    # OPTARR is defined in arrange_args() 
    set -- "${OPTARR[@]}"
   
    # Process options
    OPTIND=1
    while getopts "$optstr" opt; do
        case $opt in
            b        ) BUILD_METHOD=${OPTARG} ;;
            c        ) RUN_TEST_CASES=${OPTARG} ;;
            d        ) TARGET_DIR=${OPTARG} ;;
            e        ) FILE_EXPRESSION=${OPTARG} ;;
            g        ) DEBUG_EXEC=${OPTARG} ;;
            o        ) OUTPUT_DIR=${OPTARG} 
                       OUTPUT_DIR_NL="${OUTPUT_DIR}/nl/" ;;
            q        ) SIZE_THRESH=$OPTARG ;;
            r        ) REMOVE_FLAG=true ;;
            s        ) SPEED_THRESH=$OPTARG ;;
            t        ) RUN_TEST_ID=${OPTARG} ;;
            v        ) VERBOSE_MODE=true ;; 
            x        ) NIXEXIT_MODE=true ;; 
            \?       ) print_usage
                       exit $EXIT_FAILURE ;;
        esac
    done
    shift $((OPTIND-1))
  
    # Define array of executables that will be tested
    # $@ is stripped of all valid options
    if [[ $# -ne 0 ]]; then
        EXEC_ARRAY=( "$@" )
    fi
    # If running cross platform tests i.e. 
    # ./run_xpl_tests.sh no execs needed.
    if [[ $0 =~ "xpl" ]]; then
        EXEC_ARRAY=()        
    fi
    NUM_EXEC=${#EXEC_ARRAY[@]}

    # TODO Move this test to scripts where it matters
    # Check to make sure we have at least two executables
    #if (( NUM_EXEC <= 1 ));
    #then
    #    print_error
    #    print_usage
    #    exit $EXIT_FAILURE
    #fi

    # Check if executables are in PATH  
    for (( i=0; i<$NUM_EXEC; i++ )); 
    do
    	ex=${EXEC_ARRAY[$i]}
        hash $ex &> /dev/null
        if [ $? -eq 0 ]; then
            VALID_EXEC_ARRAY+=($ex)
            ((NUM_VALID_EXEC++))
    	else
            if [ "$VERBOSE_MODE" = true ]; then
                NO_TEST_MESSAGE+=("NO TEST:    \t'${ex}' does not exist...\n")
            fi
            ((NUM_NO_TEST++))
    	fi
    done
    
    # TODO Move this test to scripts where it matters
    # Check to make sure we have at least two valid! executables
    #if (( NUM_VALID_EXEC <= 1 ));
    #then
    #    print_error
    #    print_usage
    #    exit $EXIT_FAILURE
    #fi
    
    # TODO Move this test to where it matters
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
            printf "\nERROR:\tUnable to detect OS type...\n"
            exit $EXIT_FAILURE
    fi
}


# Function: 
# Include the script and write a nl file
# Usage: run_ampl_script ampl script filename time_file
function run_ampl_script {
	# -b4 => interactive mode!
	$1 -b4 > /dev/null 2>&1 <<!!!
	include $2;
	write g$3;
	printf "id:$test_id	tag:$test_tag	ampl_time:%f	solve_time:%f\n", _ampl_time, _solve_time>>$4;
	q;
!!!
	# Allow lazy evaluation
	touch "$3.nl"
}

# Function:
# Write a .run script for ampl with the model and data file of a problem.
# Just reset, load model and data, write nl, solve, write nl again.
# Usage: run_model_data ampl model data f1 f2 time_file
function run_model_data {
	# -b4 => interactive mode!
	$1 -b4 > /dev/null 2>&1 <<!!!
	printf "# Artificial NL test for $1 and $2\n";
	option solver gurobi;
	reset;
	model $2;
	reset data;
	data $3;
	#printf "# Write .nl for $2 and $3 (before solving)\n";
	write g$4;
	#printf "# Solve with $2 and $3\n";
	solve;
	#printf "# Write .nl for $2 and $3 (after solving)\n";
	write g$5;
	printf "id:$test_id	tag:$test_tag	ampl_time:%f	solve_time:%f\n", _ampl_time, _solve_time>>$6;
	q;
!!!
	# Allow lazy evaluation
	touch "$4.nl"
	touch "$5.nl"

}


# Function:
# Compare 2 nl files except the first line, as it is always different.
# A regular expression with diff is used for that.
# Usage: compare_nl_files file1 file2 [message]
function compare_nl_files {
	# If nl files are missing or do not exist: NO TEST
	if [ ! -s "$1" ] || [ ! -s "$2" ]; then
		if [[ "$VERBOSE_MODE" = "true" ]]; then
			echo "id: $test_id NO TEST:  ${1#"$OUTPUT_DIR_NL"} and ${2#"$OUTPUT_DIR_NL"} $3  ..."
		fi
		((no_tests++))
		return $EXIT_ERROR
	fi
	# all the nl files start with a line with this RE
	# '^g.*# problem .*$'
	if diff --ignore-matching-lines='^g.*# problem .*$' <(tail -n +1 $1) <(tail -n +1 $2) >/dev/null 2>&1;
	then
		if [[ "$VERBOSE_MODE" = "true" ]]; then
			echo "id: $test_id PASSED TEST:  ${1#"${OUTPUT_DIR_NL}"} and ${2#"${OUTPUT_DIR_NL}"} $3  ..."
		fi
		((ok_tests++))
		return $EXIT_SUCCESS
	fi
	echo "id: $test_id FAILED TEST:  ${1#"${OUTPUT_DIR_NL}"} and ${2#"${OUTPUT_DIR_NL}"} $3  ..."
	((failed_tests++))
	# Update stat if failure
	stat=$EXIT_FAILURE
	return $EXIT_FAILURE
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
    # Set md5_ref command based on host OS
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


# Function: get_host_os
# determines which operating system 
# the script is executed on
# Input:
#   1. variable $1 to hold values
# Sets variables:
#   1. $1
get_host_os() {
    local -n os_ref=$1
    # Set os_ref accordingly
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        os_ref="linux-gnu"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os_ref="darwin"
    elif [[ "$OSTYPE" == "msys"* ]]; then
        os_ref="msys"
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        os_ref="freebsd"
    else
            print_error
            printf "MESSAGE: Unable to detect host OS type...\n"
            exit $EXIT_FAILURE
    fi
}


# Function: get_target_os
# determines which operating system 
# an exec is intended for
# Input:
#   1. variable $1 to hold values
#   2. variable $2 holds name of exec
# Sets variables:
#   1. $1
get_target_os() {
    local -n os_ref=$1
    fdesc=$(file $(which $2))
    if [[ ${fdesc,,} =~ "linux" ]]; then
        os_ref="linux"
    elif [[ ${fdesc,,} =~ "mach-o" ]]; then
        os_ref="macos"
    elif [[ ${fdesc,,} =~ "windows" ]]; then
        os_ref="windows"
    else
            print_error
            printf "INFO:\n\tUnable to detect target OS type for exec:$2 ...\n"
            exit $EXIT_FAILURE
    fi
}


# Function: get_target_arch
# determines which architecture (e.g. ARM 64-bit)
# an exec is intended for
# Input:
#   1. variable $1 to hold values
#   2. variable $2 holds name of exec
# Sets variables:
#   1. $1
get_target_arch() {
    local -n arch_ref=$1
    # get file description using file command
    fdesc=$(file $(which $2))
    # ${fdesc,,} make it all lower case to help matching
    if [[ ${fdesc,,} =~ "intel 80386" ]]; then
        arch_ref="ia32"
    elif [[ ${fdesc,,} =~ "x86"[_-]"64" ]]; then
        arch_ref="x64"
    elif [[ ${fdesc,,} =~ "aarch64" ]]; then
        arch_ref="aarch64"
    elif [[ ${fdesc,,} =~ "ppc64" ]]; then
        arch_ref="ppc64"
    else
            print_error
            printf "INFO:\n\tUnable to detect arhcitecture type for exec:$2 ...\n"
            exit $EXIT_FAILURE
    fi
}



# Function: get_sed
# determines which sed command to call depending
# on the operating system
# Input:
#   1. variable $1 to hold values
# Sets variables:
#   1. $1
get_sed() {
    local -n sed_ref=$1
    # Set sed_ref command based on host OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sed_ref="sed"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        sed_ref="gsed"
    elif [[ "$OSTYPE" == "msys" ]]; then
        sed_ref="sed"
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        sed_ref="sed"
    else
            print_error
            printf "MESSAGE: Unable to detect OS type...\n"
            exit $EXIT_FAILURE
    fi
}
