#!/bin/bash
if [ "$#" -ne 1 ]; then
  	echo "Usage: $0 <URL>"
    exit 1
fi
set -ex

URL=$1
PACKAGE=`basename $URL`
if [ ! -f $PACKAGE ]; then
    curl -k -O $URL
fi
if [[ $PACKAGE == *.zip ]]; then
    unzip $PACKAGE
else
    tar xzvf $PACKAGE
fi
rm $PACKAGE
mv `ls | egrep "ampl.?(linux|mac|mswin)"` ampl
cd ampl
pwd
