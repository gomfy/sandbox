#!/usr/bin/env bash

# Author(s): 	Gyorgy Matyasfalvi <matyasfalvi@ampl.com>, 
#
#
# Description:  Prepares the test outputs for cross platform testing i.e.
#               1. Moves 32-bit linux results to new folders
#                  This is necessary so to ensure that 32 bit results
#                  are tested and compared against each other
#               2. Adjusts windows line endings
#                  This is necssary so that we can process time
#                  results appropriately
# 

# If debugging turn on -xve
#set -xve

# Load user defined variables and functions
source ./functions.sh
STAT=$EXIT_SUCCESS

# Parse arguments and set variables
parse_args "$@" 

# Check if output dir exists if no create it.
if [ ! -d "$TARGET_DIR" ]; then
    mkdir "$TARGET_DIR"
fi

# Set working directory
cd "$TARGET_DIR"

if [ "$VERBOSE_MODE" = true ]; then
    printf "\n### START XPL FILE PREPARATION  ###\n"
else
    printf "\nPrepping files for xpl tests...\n"
fi

# Define array of directories that hold
# outputs of .cases scripts
dir_array=($(find . -type d -regextype posix-egrep -regex '.*(windows|macos|linux|dockcross).*'))
if (( $? != 0 )); then
    STAT=$EXIT_FAILURE
    print_error
    printf "\nINFO:\n"
    printf "\tfind command error...\n"
fi
num_dir=${#dir_array[@]}

# Test for empty directory
if (( num_dir <= 0)); then
    STAT=$EXIT_FAILURE
    print_error
    printf "\nINFO:\n"
    printf "\tTARGET_DIR:$TARGET_DIR does not contain any files...\n"
fi

# Loop through all the directories
# 1. If it's a linux directory create 32-bit directory and 
# move 32 bit files to that directory
# 2. If it's a windows directory adjust line endings to 
# linux line endings
for (( i=0; i<$num_dir; i++ ));
do        
        # Define shorthands for various directories
        dir=${dir_array[$i]}

        if [[ $dir =~ "manylinux" && $STAT -eq $EXIT_SUCCESS ]]; then
            
            if [ "$VERBOSE_MODE" = true ]; then
                printf "MOVING 32-BIT FILES IN:\t$dir...\n"
            fi
            # Create new directory name
            dir32="${dir}_32"
            mkdir -p $dir32
            
            # Get the list of all 32-bit files
            file32_array=($(find $dir -type f -regextype grep -regex ".*32.*"))
            if (( $? != 0 )); then
                STAT=$EXIT_FAILURE
                print_error
                printf "\nINFO:\n"
                printf "\tfind command error...\n"
            fi
            num_file32=${#file32_array[@]}

            # Test for 32-bit files
            if (( num_file32 <= 0)); then
                STAT=$EXIT_FAILURE
                print_error
                printf "\nINFO:\n"
                printf "\tdir:$dir does not contain any files with '32' in name...\n"
            fi
            
            # Move all files to new directory 
            for (( j=0; j<$num_file32; j++ ));
            do
                mv ${file32_array[$j]} $dir32
            done

        elif [[ $dir =~ "windows" && $STAT -eq $EXIT_SUCCESS ]]; then  

            if [ "$VERBOSE_MODE" = true ]; then
                printf "ADJUSTING LINE ENDINGS IN:\t$dir...\n"
            fi
            
            # Get the list of all files
            filewin_array=($(find $dir -type f -regextype grep -regex ".*"))
            if (( $? != 0 )); then
                STAT=$EXIT_FAILURE
                print_error
                printf "\nINFO:\n"
                printf "\tfind command error...\n"
            fi
            num_filewin=${#filewin_array[@]}

            # Test for windows files
            if (( num_filewin <= 0)); then
                STAT=$EXIT_FAILURE
                print_error
                printf "\nINFO:\n"
                printf "\tdir:$dir does not contain any files...\n"
            fi
            
            # Convert windows line endings to linux 
            for (( j=0; j<$num_filewin; j++ ));
            do
                cat ${filewin_array[$j]} | tr -d "\r" | tee ${filewin_array[$j]} > /dev/null
                STAT=$?
            done
        fi
done

if [ "$VERBOSE_MODE" = true ]; then
    printf "### END XPL FILE PREPARATION  ###\n"
fi

# If nix-exit mode is not truned on call exit
if [ "$NIXEXIT_MODE" = false ]; then
    exit $STAT
fi
