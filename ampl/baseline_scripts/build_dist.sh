#!/bin/bash
set -ex

if [[ "$#" -ne 2 ]]; then
    echo "Usage: $0 <dist dir> <platform>"
    exit 1
fi

DIR=$1
PLATFORM=$2
cd $DIR

# Build regular executable
make -f makefile.$PLATFORM CFLAGS="-O2"
mv amplx ampl

# Build time-limited executable
cp licmain.c licmain1.c
cp licmain_tl.c licmain.c
rm {licmain,version}.o
make -f makefile.$PLATFORM CFLAGS="-O2 -DTIME_LIMITED"
mv licmain1.c licmain.c
mv amplx ampl-tl

# Check version
./ampl --version
./ampl-tl --version

# Clean
make -f makefile.$PLATFORM clean
