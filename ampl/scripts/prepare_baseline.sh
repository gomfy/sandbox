#!/bin/bash
set -ex

ORG_PWD=$PWD
FINGERPRINT=""
if [[ "$#" -eq 1 ]]; then
    PLATFORM=$1
elif [[ "$#" -eq 2 ]]; then
    PLATFORM=$1
    FINGERPRINT=$2
else
    echo "Usage: $0 <platform> [fingerprint]"
    exit 1
fi
cd "`dirname "$0"`/../"

USE_AMPLKEY=1

# x64
LINUX64_BUNDLE_URL='https://ampl.com/demo/ampl.linux64.tgz'
MACOS64_BUNDLE_URL='https://ampl.com/demo/ampl.macos64.tgz'
MSWIN64_BUNDLE_URL='https://ampl.com/demo/ampl.mswin64.zip'
LINUX64_TABLES_URL='https://ampl.com/dl/fdabrandao/tables/linux64/tables.zip'
MACOS64_TABLES_URL='https://ampl.com/dl/fdabrandao/tables/macos/tables.zip'
MSWIN64_TABLES_URL='https://ampl.com/dl/fdabrandao/tables/win64/tables.zip'
# x86
LINUX32_BUNDLE_URL='https://ampl.com/demo/ampl.linux32.tgz'
MSWIN32_BUNDLE_URL='https://ampl.com/demo/ampl.mswin32.zip'
LINUX32_TABLES_URL='https://ampl.com/dl/fdabrandao/tables/linux32/tables.zip'
MSWIN32_TABLES_URL='https://ampl.com/dl/fdabrandao/tables/win32/tables.zip'
case $PLATFORM in
  linux-intel64)
    BUNDLE_URL=$LINUX64_BUNDLE_URL
    TABLES_URL=$LINUX64_TABLES_URL
    ;;
  macos64)
    BUNDLE_URL=$MACOS64_BUNDLE_URL
    TABLES_URL=$MACOS64_TABLES_URL
    ;;
  mswin64)
    BUNDLE_URL=$MSWIN64_BUNDLE_URL
    TABLES_URL=$MSWIN64_TABLES_URL
    ;;
  linux-intel32)
    BUNDLE_URL=$LINUX32_BUNDLE_URL
    TABLES_URL=$LINUX32_TABLES_URL
    ;;
  mswin32)
    BUNDLE_URL=$MSWIN32_BUNDLE_URL
    TABLES_URL=$MSWIN32_TABLES_URL
    ;;
  *)
    echo -n "Unknown platform"
    exit 1
    ;;
esac

rm -rf ampl tables
scripts/download_ampl.sh $BUNDLE_URL
scripts/download_tables.sh $TABLES_URL
cp tables/{simpbit.dll,fullbit.dll} ampl/
if [ $USE_AMPLKEY -eq 0 ]; then
    cp ampl.lic ampl/
else
    cp ampl.lic.base ampl/ampl.lic
    cp scripts/amplkey.py ampl/
    /usr/bin/env python3 -m pip install requests
    case $PLATFORM in
    mswin32 | mswin64)
        #echo "AMPLKEY_RENEW_CMD=python3 \"%AMPL_INSTALL_DIR%/amplkey.py\" \"%AMPL_INSTALL_DIR%/ampl.lic\"" > ampl/ampl.env
        echo "AMPLKEY_RENEW_CMD=python3 amplkey.py ampl.lic" > ampl/ampl.env
        ;;
    *)
        echo "AMPLKEY_RENEW_CMD=python3 \"\$AMPL_INSTALL_DIR/amplkey.py\" \"\$AMPL_INSTALL_DIR/ampl.lic\"" > ampl/ampl.env
        ;;
    esac
    PATH=ampl/:$PATH ampl/amplkey.py ampl/ampl.lic
fi
if [ ! -z "$FINGERPRINT" ]; then
    AMPL_DIR=$PWD/ampl
    cd $ORG_PWD
    case $PLATFORM in
    mswin32 | mswin64)
        mv $AMPL_DIR/fingerprint.exe $AMPL_DIR/fingerprint-baseline.exe
        cp "$FINGERPRINT" $AMPL_DIR/fingerprint.exe
        ;;
    *)
        mv $AMPL_DIR/fingerprint $AMPL_DIR/fingerprint-baseline
        cp "$FINGERPRINT" $AMPL_DIR/fingerprint
        ;;
    esac
    cd -
fi
mv ampl/ampl ampl/ampl-baseline || mv ampl/ampl.exe ampl/ampl-baseline.exe
