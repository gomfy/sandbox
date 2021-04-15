#!/usr/bin/env bash

fdesc=$(file $(which cat))

if [[ ${fdesc,,} =~ windows ]]; then
    printf "linux\n"
fi
