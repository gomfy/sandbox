#!/usr/bin/env bash

printf "windows line\r\n" > file.win
printf "unix line\n" > file.unix
cat file.win | tr -d "\r" | tee file.win > /dev/null
cat file.unix | tr -d "\r" | tee file.unix > /dev/null
printf "file.win:\n"
file file.win
cat file.win
printf "file.unix:\n"
file file.unix
cat file.unix


