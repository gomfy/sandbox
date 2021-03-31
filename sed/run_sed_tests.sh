#!/usr/bin/env bash

cat file.1 | sed --regexp-extended 's/([0-9]+)([^0-9]+iterations)/XXX\2/' 
