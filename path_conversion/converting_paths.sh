#!/usr/bin/env bash

# Cygpath tests based on:
# https://cygwin.com/cygwin-ug-net/cygpath.html

echo "### BEGIN TEST ###"

apath1=/home/invented/unix/path.file
apath2="/home/invented/unix/path.aaa"
rpath1=../mypath
rpath2="../../path?nl"

echo "Current dir: $(pwd)"
echo "Current dir (Windows): $(cygpath -w `pwd`)"

echo "$apath1 conversion to Windows is:"
echo "$(cygpath -w $apath1)"
echo "Now absolute: $(cygpath -w -a apath1)"

echo "$apath2 conversion to Windows is:"
newpath=`cygpath -w apath2`
echo "$newpath"
newpath=`cygpath -w -a apath2`
echo "Now absolute: $newpath"

echo "$rpath1 conversion to Windows is:"
echo "$(cygpath -w -m $rpath1)"
echo "Now absolute: $(cygpath -w -a -m rpath1)"

echo "$rpath2 conversion to Windows is:"
echo "$(cygpath -w -m $rpath2)"
echo "Now absolute: $(cygpath -w -a -m rpath2)"

echo "### END TEST ###"

exit 0

















