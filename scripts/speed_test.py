#!/usr/bin/env python3
import os
import sys
import shutil
import tempfile
import subprocess
from time import time

TMP = tempfile.mkdtemp()
NRUNS = 5


def str2file(filename, content):
    fullpath = os.path.join(TMP, filename)
    with open(fullpath, 'w') as f:
        print(content, file=f)
    return fullpath


if __name__ == '__main__':
    fname = str2file('test.run', '''
    display card({i in 1..100, j in i..100, k in 1..1000, l in 1..2: 2*i=-j*k+l});
    ''')

    executables = sys.argv[1:]
    if executables == []:
        print('Usage: {} <executable 1> <executable 2> ...'.format(
            sys.argv[0]))
        sys.exit(1)

    tests = [
        [fname],
        ["-vvq"],
    ]

    for test in tests:
        print('test:', test)
        average = {}
        print('runs:')
        for executable in executables:
            total = 0
            name = os.path.basename(executable)
            print('{:15}:'.format(name), end='')
            for i in range(NRUNS):
                t0 = time()
                try:
                    res = subprocess.Popen(
                        [executable] + test,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE)
                    res.wait()
                    # print(res.stdout.read())
                except OSError:
                    print('Error: failed to run {}'.format(executable))
                    sys.exit(-1)
                t1 = time()
                dif = t1-t0
                print(' {:.3f}'.format(dif), end='', flush=True)
                total += dif
            average[executable] = total / NRUNS
            print()

        print('\naverage times:')
        for executable in executables:
            name = os.path.basename(executable)
            print('{:15}: {}'.format(name, average[executable]))
        print('\n\n')

    shutil.rmtree(TMP)
