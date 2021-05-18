#!/bin/bash
cd `dirname $0`/..
set -ex

# Step 1: compile tools
cd src
make clean
make

# Step 2: update path
cd ..
. bin/p

# Step 4: compile ax
cd acl
rm *.hd hd.files|| true
mk clean
mk

# Check version
./ax --version
