#!/bin/bash

set -exv

cd ~/ampl/git/escrow.tests
./run_tests.sh cmake-ax ampl
