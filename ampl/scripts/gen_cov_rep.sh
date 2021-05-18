#!/bin/bash

#
# Description: this script create a report of the coverage from an specific executable file.
# The process is based in LCOV, see the Wiki:
# https://github.com/ampl/escrow/wiki/Scripts#coverage-tests
# or see the LCOV website:
# http://ltp.sourceforge.net/coverage/lcov.php
# 
# Example of usage:
#     ./gen_cov_rep.sh -d ../build/CMakeFiles/ampl.dir/cpp -o ../coverage_report
# 
# In the coverage_report folder you can find the index.html file which contains the information
# 

# To debug:
#set -xve

# Reset flag
RESET_COV=false
# Source directory
SRCDIR=../build/CMakeFiles/ampl.dir/cpp
# Folder where html files are created
REPORT_FOLDER=../coverage_report

# Parse arguments
while getopts rd:o: opts; do
   case ${opts} in
      r) RESET_COV=true ;;
      d) SRCDIR=${OPTARG} ;;
      o) REPORT_FOLDER=${OPTARG} ;;
      ?) echo "Usage: $0 [-r] [-d SRCDIR] [-o REPORT_FOLDER]"
      printf "\t -r: reset to zero the counters.\n"
      printf "\t -d: directory of the source code. Default: $SRCDIR\n"
      printf "\t -o: Folder where the report is created. Default: $REPORT_FOLDER\n"
      exit 0 ;;
   esac
done

# Set counters to zero
if $RESET_COV ; then
    lcov --zerocounters --directory $SRCDIR                                         
    echo "The coverage results have been reset!"
	exit 0
fi

# Reset the coverage folder
if [ -d $REPORT_FOLDER ];
then
	rm -r $REPORT_FOLDER
fi
mkdir -p $REPORT_FOLDER

# Get the coverage
lcov --capture --directory $SRCDIR --output-file $REPORT_FOLDER/gcov_test.info

# Generate the html report
cd $REPORT_FOLDER
genhtml --ignore-errors source gcov_test.info

exit 0
