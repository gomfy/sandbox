#!/usr/bin/env python3
import re
import sys
import base64
from subprocess import check_output

if __name__ == '__main__':
    executables = sys.argv[1:]
    if executables == []:
        print('Usage: {} <executable 1> <executable 2> ...'.format(
            sys.argv[0]))
        sys.exit(1)
    outputs = {}
    for executable in executables:
        print('executable:', executable)
        output = check_output([executable, '-s']).decode()
        decoded = base64.b64decode(output).decode()
        print('base64:', output)
        print('decoded:', decoded)
        clean = re.sub(
            r'Fingerprint\(\d+\) = .*', 'Fingerprint(YYYYMMDD) = H-A-L-HASH', decoded)
        clean = re.sub(
            r'(?m)^_HOSTINFO\..*\n?', '', clean)
        # print('clean:', clean)
        outputs[executable] = clean
    assert len(set(outputs.values())) == 1
