#!/bin/bash
cd "`dirname "$0"`"
cd ..

if [[ "$#" -eq 2 && "$1" =~ \.gpg$ ]]; then
    passphrase=$2
elif [[ "$#" -eq 1 && "$1" =~ \.gpg$ ]]; then
    read -p "Enter passphrase: " passphrase
else
    echo "Usage: $0 <file.gpg> [passphrase]"
    exit 1
fi

set -ex

gpg_file=$1
tgz=`basename $gpg_file .gpg`
echo -n $passphrase | gpg --decrypt --ignore-mdc-error --batch --yes --passphrase-fd 0 $gpg_file > $tgz
# tar zxvf $tgz
