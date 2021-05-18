#!/bin/bash
set -ex

DATE=`date --date="+1month" +%Y%m%d || date -v+1m +%Y%m%d`
for FILE in $*; do
    `dirname $0`/tladjust.py $FILE $DATE "For testing"
done
