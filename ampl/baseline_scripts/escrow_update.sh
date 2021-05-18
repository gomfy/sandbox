#!/bin/bash
#set -ex

if [[ "$#" -eq 1 ]]; then
    ESCROW=`cd "$1"; pwd`
else
    echo "Usage: $0 <escrow directory>"
    exit 1
fi
cd "`dirname "$0"`"; cd ..

cd original/
for f in `find . -type f`; do
    mv $ESCROW/$f $f || true
done
cd ..

cp -r $ESCROW/* .
cd dist; git clean -fdx; git checkout .; cd ..
cd acl/lcsrc; git clean -fdx; cd ../..
git checkout src
sed -i~ 's/^#include "main0\.c"$/\/\/#include "main0.c"/' acl/version.c
rm acl/pathset
rm acl/xsum0.out
