#!/usr/bin/env bash

a=( "fjklsj" "kldj" "123" 39874 993 )
printf "\nElements of array 'a':\n"
printf "%s\n" "${a[@]}"

a23=( ${a[@]:2} )
printf "\nElements of array 'a23':\n"
printf "%s\n" "${a23[@]}"

