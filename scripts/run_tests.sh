#!/bin/bash

# This file tests ampl and any other executable files by using some different tests:
# speed tests, regression tests by output comparison, and nl files comparison.
# If something fails -> exit 134, else exit 0

cd "`dirname "$0"`"
set -e

# Check executables
echo "Check sizes"
for x in "$@"; do
    ls -l `which $x`
done

EXIT_SUCCESS=0
EXIT_FAILURE=134

stat=$EXIT_SUCCESS

# Run tests
set +e
echo -e "\n# Run speed_test.py"
./speed_test.py "$@"

# echo -e "\n# Run run_nl_tests.sh"
# Activate -v with `./run_nl_tests.sh -v "$@"` to debug in verbose mode
# ./run_nl_tests.sh "$@"
# if [[ $? -eq $EXIT_FAILURE ]]; then
#	stat=$EXIT_FAILURE
# fi

echo -e "\n# Run run_output_tests.sh"
./run_output_tests.sh "$@"
if [[ $? -eq $EXIT_FAILURE ]]; then
	stat=$EXIT_FAILURE
fi
set -e
# End running tests

exit $stat
# stat = 0   if everything passed
# stat = 134 if something has failed

