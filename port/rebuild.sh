#!/bin/bash
# set -xve
rm -r build
mkdir build
cd build


if [[ $1 == 'cpp' ]]; then
	cmake .. -DCPLUSPLUS=ON
	cmake --build . -v
else
	cmake ..
	cmake --build . -v
fi
