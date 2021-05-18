#!/bin/bash
BASEDIR=$(cd "`dirname "$0"`"; pwd)
set -ex
export PATH="$BASEDIR/../:$PATH" # because of ampl.lic
for x in "$@"; do
    echo "option version; display 1..10;" | $x
done