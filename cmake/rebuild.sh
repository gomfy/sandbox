#!/bin/bash
# set -xve
rm -r build
mkdir build
cd build

if [[ $1 == 'mingw' ]]; then
	cmake -G "MinGW Makefiles" ..
	cmake --build . -v
elif [[ $1 == 'msvc' ]]; then
	if [[ $2 == 'fix' ]]; then
		cmake .. -DFIX=ON
		cmake --build . -v
	else
		cmake ..
		cmake --build . -v
	fi
else
	echo "Need to specify compiler: mingw or msvc"
	exit 2
fi

