#!/usr/bin/env bash

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sed_cmd=sed
elif [[ "$OSTYPE" == "darwin"* ]]; then
    sed_cmd=gsed
elif [[ "$OSTYPE" == "msys"* ]]; then
    sed_cmd=sed
else
        print_error
        printf "MESSAGE: Unable to detect host OS type...\n"
        exit $EXIT_FAILURE
fi

cat file.1 | $sed_cmd --regexp-extended 's/([0-9]+)([^0-9]+iterations)/XXX\2/' 

