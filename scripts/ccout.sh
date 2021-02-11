#!/bin/bash
cd ~/ampl/out_files && ls -ltr | awk '{ print $9 }' | tail -n 2 | xargs Meld 
