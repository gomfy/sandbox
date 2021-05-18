#!/bin/bash
BASEDIR=$(cd "`dirname "$0"`"; pwd)
# Author: 	Gyorgy Matyasfalvi <matyasfalvi@ampl.com>
#
# Description: 	Checks the content of symbol tables of executables. 
#       The executables are passed as arguments to the script.
#		A test instance comprises of comparing the outputs of the nm
#       command with cmp.
#		If the files are identical the test passes otherwise it fails.

# If debugging turn on -xve
#set -xve

# Define array of executables that will be tested
if [ "$#" -eq 0 ]; then
  exec_array=("origb-ax" "newb-ax")
else
  exec_array=( "$@" )
fi
num_exec=${#exec_array[@]}

# Create a directory for test output files
TESTOUT="$BASEDIR/../tests/testout"
if [ -d $TESTOUT ];
then
	rm -r $TESTOUT
	mkdir $TESTOUT
else
	mkdir $TESTOUT
fi

# Set return status to zero
stat=0

# Set pass, fail, total test, no test, and total attempt counter
ctpass=0
ctfail=0
cttottest=0
ctnot=0
cttotatte=0

printf "\n### START TESTING ###\n\n"

# Select pairs of ampl executables from exec_array and compare their symbol tables
for (( i=0; i<$num_exec; i++ )); 
do
	for (( j=$i+1; j<$num_exec; j++ )); 
	do	
		ex1=${exec_array[$i]}
		ex2=${exec_array[$j]}
		ex1_name=`basename $ex1`_1_$i_$j
		ex2_name=`basename $ex2`_2_$i_$j
		if [[ -x "$(command -v $ex1)" && -x "$(command -v $ex2)" ]]; 
		then
			f1="$TESTOUT/${ex1_name}_sym.txt"
			f2="$TESTOUT/${ex2_name}_sym.txt"
			nm "$(which $ex1)" &> $f1
			nm "$(which $ex2)" &> $f2

			if cmp -s $f1 $f2;
			then
				echo "PASSED TEST: symbol tables of  ${ex1}  and  ${ex2}  are the same."
                ((ctpass++))
			else
				echo "FAILED TEST: symbol tables of  ${ex1}  and  ${ex2}  are different."
                ((ctfail++))
                stat=134
			fi
			
            if (( stat == 134 ));
            then
                f1="$TESTOUT/${ex1_name}_sym23.txt"
		    	f2="$TESTOUT/${ex2_name}_sym23.txt"
		    	nm "$(which $ex1)" | awk '{ print $2,$3 }' &> $f1
		    	nm "$(which $ex2)" | awk '{ print $2,$3 }' &> $f2

		    	if cmp -s $f1 $f2;
		    	then
		    		echo "PASSED TEST: 2nd and 3rd columns of symbol tables of  ${ex1}  and  ${ex2}  are the same."
                    ((ctpass++))
		    	else
		    		echo "FAILED TEST: 2nd and 3rd columns of symbol tables of  ${ex1}  and  ${ex2}  are different."
                    ((ctfail++))
                    stat=135
		    	fi
            fi
            
            if (( stat == 135 ));
            then
                f1="$TESTOUT/${ex1_name}_fun.txt"
		    	f2="$TESTOUT/${ex2_name}_fun.txt"
		    	nm "$(which $ex1)" | awk '{ if ($2 == "T") print $3 }' &> $f1
		    	nm "$(which $ex2)" | awk '{ if ($2 == "T") print $3 }' &> $f2

		    	if cmp -s $f1 $f2;
		    	then
		    		echo "PASSED TEST: defined functions in symbol tables of  ${ex1}  and  ${ex2}  are the same."
                    ((ctpass++))
		    	else
		    		echo "FAILED TEST: defined functions in symbol tables of  ${ex1}  and  ${ex2}  are different."
                    ((ctfail++))
                    stat=136
		    	fi
            fi
            
		else
			echo -e "NO TEST:      either  ${ex1}  or  ${ex2}  does not exist..."
            ((ctnot++)) 
		fi
	done
done
printf "\n### END TESTING ###\n\n"

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

exit $stat
