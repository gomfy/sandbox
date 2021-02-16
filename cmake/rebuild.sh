#!/bin/bash
# set -xve
rm -r build
mkdir build
cd build

if [[ $1 == 'mingw' ]]; then
	if [[ $2 == 'cpp' ]]; then
		cmake -G "MinGW Makefiles" .. -DCPLUSPLUS=ON
		cmake --build . -v
	else
		cmake -G "MinGW Makefiles" ..
		cmake --build . -v
	fi
elif [[ $1 == 'msvc' ]]; then
	if [[ $2 == 'fix' ]]; then
		if [[ $3 == 'cpp' ]]; then
			cmake .. -DFIX=ON -DCPLUSPLUS=ON
			cmake --build . -v
		else
			cmake .. -DFIX=ON
			cmake --build . -v
		fi
	else
		cmake ..
		cmake --build . -v
	fi
else
	echo "Need to specify compiler: mingw or msvc"
	exit 2
fi

