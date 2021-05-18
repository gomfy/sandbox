#!/bin/bash
if [ "$#" -lt 4 ]; then
  echo "Usage: $0 <upload basedir> <variant> <platform> <executable> [fingerprint]"
  exit 1
fi
set -ex
UPLOAD_BASE=$1
VARIANT=$2
PLATFORM=$3
EXECUTABLE=$4
FINGERPRINT=$5
VERSION=`$EXECUTABLE --version | cut -d" " -f3`

echo $PLATFORM
if [[ "$PLATFORM" == mswin* ]]; then
    AMPL_NAME="ampl.exe"
    FP_NAME="leasefingerprint.exe"
    PKG_NAME=$VARIANT.$PLATFORM.$VERSION.zip
else
    AMPL_NAME="ampl"
    FP_NAME="leasefingerprint"
    PKG_NAME=$VARIANT.$PLATFORM.$VERSION.tgz
fi

RELEASE_DIR=$UPLOAD_BASE/release/$VARIANT/$PLATFORM/
PKG_DIR=$UPLOAD_BASE/release/packages/
mkdir -p $RELEASE_DIR
mkdir -p $PKG_DIR

cp $EXECUTABLE $RELEASE_DIR/$AMPL_NAME
if [ ! -z "$FINGERPRINT" ]; then
    cp $FINGERPRINT $RELEASE_DIR/$FP_NAME
fi

cd $RELEASE_DIR
if [[ "$PKG_NAME" == *.zip ]]; then
    7z a -tzip $PKG_NAME *
else
    tar czvf $PKG_NAME *
fi
cd -
mv $RELEASE_DIR/$PKG_NAME $PKG_DIR
