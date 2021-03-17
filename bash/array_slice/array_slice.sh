#!/usr/bin/env bash

defaultIFS=$IFS
IFS=$'\n'
t=($(awk '{ printf("%s\n", $0) }' "$1"))
printf "\nArray 't' has ${#t[@]} elements\n"
printf "Elements of array 't':\n"
printf "%s\n" "${t[@]}"

t45=( "${t[@]:4}" )
printf "\nArray 't45' has ${#t45[@]} elements\n"
printf "Elements of array 't45':\n"
printf "%s\n" "${t45[@]}"

