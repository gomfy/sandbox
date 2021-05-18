#!/bin/bash
cd `dirname $0`/..
set -ex
# Build script following the instructions in README
# Should work in Ubuntu 18.04 x64

# Step 1: compile tools
cd src
make clean
make

# Step 2: update path
cd ..
. bin/p

# Step 3: update patches
cp bin/CC.ubuntu bin/CCf
cp acl/as.ubuntu acl/as.

# Step 4: compile ax
cd acl
rm *.hd hd.files || true
mk clean
mk

# Step 5: update dist/
mk dist

# Step 6: compile ampl
cd ..
scripts/build_dist.sh dist linux64
