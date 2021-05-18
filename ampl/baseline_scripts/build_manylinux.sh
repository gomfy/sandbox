#!/bin/bash
cd `dirname $0`/..
BASEDIR=`pwd`
set -ex

if [ "$#" -eq 1 ]; then
    NBITS=$1
elif [ "$#" -eq 0 ]; then
    if [[ `arch` == "i686" ]]; then
        NBITS=32
    else
        NBITS=64
    fi
else
    echo "Usage: $0 <nbits>"
    exit 1
fi

CORE=/tmp/core
rm -rf $CORE
mkdir -p $CORE
cp -ra {acl,bin,dist,lib,src,ampl_dist,scripts} $CORE/
cd $CORE
CORE=$PWD
echo $CORE

# Delete all object files
find . -type f -name '*.o' -delete

# Remove general arith.h
# rm -f $CORE/acl/arith.h

# Save PATH before the 'mk dist' process
ORG_PATH=$PATH

# Build tools
rm -f $CORE/bin/{gcc,g++,cc,CCf}
ln -s `which gcc` $CORE/bin/gcc
ln -s `which g++` $CORE/bin/g++
ln -s `which gcc` $CORE/bin/cc
cd $CORE/src
touch `find . -name y.tab.c` # avoid needing yacc
make clean
make
cd ..

. bin/p
cp acl/as.manylinux acl/as.
# rm $CORE/bin/cc
cp $CORE/bin/CC.manylinux $CORE/bin/CCf

# Build ax
cd acl
rm *.hd hd.files || true
mk clean
mk

# Generate dist source
mk dist

# Restore PATH after the 'mk dist' process
export PATH=$ORG_PATH

# Prepare dist directory for Windows (avoid requiring sed.exe)
cd $CORE/dist
sed -f version_vc32.ss version.c0 > version_vc32.c
sed "s/sed.*version.c$/copy version_vc32.c version.c/" -i makefile.vc32
sed -f version_vc64.ss version.c0 > version_vc64.c
sed "s/sed.*version.c$/copy version_vc64.c version.c/" -i makefile.vc64
# Avoid requiring "." to be in $PATH (fix issues with Linux and MacOS)
# sed "s/a.out >arith.h/.\/a.out >arith.h/" -i makefile*

# Prepare ampl_dist
cd $CORE
rm -rf ampl_dist/src/*
cp -r dist/* ampl_dist/src/
cp $BASEDIR/manylinux/extra/* ampl_dist/src/

# Compile regular executable
cd $CORE
scripts/build_dist.sh dist linux$NBITS
