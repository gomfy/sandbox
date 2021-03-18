#!/usr/bin/env bash

if [ -d build ]; then
    rm -r build
    mkdir build
else
    mkdir build
fi

cd build

if [[ "$OSTYPE" == "msys" ]]; then
    cmake -A Win32 ..
    cmake --build .
else
    cmake ..
    cmake --build .
fi
