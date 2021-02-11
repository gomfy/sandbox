#!/bin/bash

set -exv

rm -r build
mkdir -p build
cd build
cmake .. -DARCH=64
cmake --build . --config Release
