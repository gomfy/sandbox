#!/bin/bash
grep "extern" file1.txt \
	print.c \
	file2.txt \ 
	file3.txt | grep "$@"

