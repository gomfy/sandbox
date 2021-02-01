#!/bin/bash
set -xve
rm -r build
mkdir build
cd build
cmake ..
cmake --build . -v

