#!/usr/bin/env bash

if [ -d build ]; then
    rm -r build
    mkdir build
else
    mkdir build
fi

cd build
cmake ..
cmake --build . -v
