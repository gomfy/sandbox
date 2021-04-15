#!/usr/bin/env bash

dirs=("/k/j/a/tmp/dir/" "/kja/t1/dir/tmp/usr/bin/environment" "../dir" "dir/tmp/z/k/" "./var/dir/" "/2021/2003/tmp/environment/")

printf "dirs:\n"
printf "%s\n" "${dirs[@]}"
printf "\n"

for i in ${dirs[@]}
do
    printf "handling: $i\n"
    if [ "${i:0:1}" == "/" ]; then
        drive_name=${i:1}
        drive_name=${drive_name%%/*}
        printf "\t  drive_name: $drive_name\n"
    fi
done
