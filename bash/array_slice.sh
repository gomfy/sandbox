#!/usr/bin/env bash

a=( "fjklsj" "kldj" "123" 39874 993 )
printf "\nElements of array 'a':\n"
printf "%s\n" "${a[@]}"

a23=( ${a[@]:2} )
printf "\nElements of array 'a23':\n"
printf "%s\n" "${a23[@]}"

defaultIFS=$IFS
IFS=$'\n'
t=($(awk '$1=="text" { printf("%s\n", $0) }' "$1"))
printf "\nElements of array 't':\n"
printf "%s\n" "${t[@]}"

t23=( ${t[@]:2} )
printf "\nElements of array 't23':\n"
printf "%s\n" "${t23[@]}"

