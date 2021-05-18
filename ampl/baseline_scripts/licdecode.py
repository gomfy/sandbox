#!/usr/bin/env python3
import re
import sys


def iran(jran):
    mult = 16807
    modul = 2147483647
    ixhi = jran >> 16
    ixlo = jran - (ixhi << 16)
    ixalo = ixlo * mult
    leftlo = ixalo >> 16
    ixahi = ixhi * mult
    ifulhi = ixahi + leftlo
    irtlo = ixalo - (leftlo << 16)
    iover = ifulhi >> 15
    irthi = ifulhi - (iover << 15)
    jran = irtlo - modul + (irthi << 16) + iover
    if jran & 0x80000000 != 0:
        jran += modul
    return jran & 0xffffffff


def decode(encoded):
    assert len(encoded) % 2 == 0
    now = int(encoded[:8], 16)
    encoded = encoded[8:]
    P = list(range(16))
    x = now | (now >> 16)
    for i in range(16):
        if x & 0x8000 != 0:
            j = (i + 1) & 0xf
            P[i], P[j] = P[j], P[i]
        x <<= 1
    x = 0
    s = encoded
    content = ''
    while s != '':
        j = 16
        if len(s) < 32:
            j = len(s) >> 1
            P = [p for p in P if p < j]
        for i in range(j):
            if x == 0:
                x = now = iran(now)
            k = 2*P[i]
            c = int(s[k], 16)
            c1 = int(s[k+1], 16)
            content += chr(((c | (c1 << 4)) ^ x) & 0xff)
            x >>= 8
        s = s[2*j:]
    return content


if __name__ == '__main__':
    assert len(sys.argv) == 2
    with open(sys.argv[1]) as f:
        license_str = f.read()
        comments = ''.join(re.findall(r'(?m)^#.*\n?', license_str))
        encoded = re.sub(r'(?m)^#.*\n?', '', license_str)
        encoded = encoded.replace('\n', '').replace(' ', '')
        decoded = decode(encoded)
        print('> comments:\n' + comments)
        print('> content:\n' + decoded)
