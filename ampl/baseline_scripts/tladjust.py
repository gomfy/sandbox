#!/usr/bin/env python3
import sys
import calendar
import time

MAGIC = b'\x11\x12\x13\x14\x18\x17\x16\x15'
MAX_DESCLEN = 256


def read_licinfo(fname):
    info, position, nbytes = {}, {}, {}

    with open(fname, 'rb') as f:
        binary = f.read()

        def read_raw(key, offset, size):
            position[key] = offset
            nbytes[key] = size
            info[key] = binary[offset:offset+size]

        def read_str(key, offset, size):
            position[key] = offset
            nbytes[key] = size
            info[key] = binary[offset:offset+size].decode()

        def read_int(key, offset, size, byteorder):
            position[key] = offset
            nbytes[key] = size
            info[key] = int.from_bytes(binary[offset:offset+size], byteorder)

        byteorder = 'little'

        # licfor
        base = binary.find(MAGIC)
        read_raw('licfor', base+len(MAGIC), MAX_DESCLEN)

        # expdate
        size = 8
        offset = base-size
        read_str('expdate', offset, size)

        # time_tlen
        size = 4
        offset -= size
        read_int('time_tlen', offset, size, byteorder)
        if size > 8:
            byteorder = 'big'
            read_int('time_tlen', offset, size, byteorder)
        info['byteorder'] = byteorder

        # uintlen
        size = 4
        offset -= size
        read_int('uintlen', offset, size, byteorder)

        # l4len
        size = info['uintlen']
        offset -= size
        read_int('l4len', offset, size, byteorder)

        # itext
        size = info['uintlen']
        offset -= size
        read_int('itext', offset, size, byteorder)

        # exptime
        size = info['time_tlen']
        offset -= max(info['time_tlen'], 2*info['uintlen'])
        read_int('exptime', offset, size, byteorder)

        # issuetime
        size = info['time_tlen']
        offset -= max(info['time_tlen'], 2*info['uintlen'])
        read_int('issuetime', offset, size, byteorder)

        # licfor_decoded
        u = info['issuetime']
        lst = list(info['licfor'])
        if info['l4len'] != 0:
            if (lst[0] ^ (u >> 1 | ((u & 1) << 31))) & 255 == 0:
                u ^= 2
                info['issuetime'] = u
        for i in range(info['l4len']):
            u = u >> 1 | ((u & 1) << 31)
            lst[i] ^= u & 255
        info['licfor_decoded'] = bytes(lst).decode()

        for k in info:
            print('{}: {} (start: {}, nbytes: {})'.format(
                k, info[k], position.get(k, None), nbytes.get(k, None))
            )

        print('License {}-{} for {}'.format(
            hex(info['issuetime'])[2:],
            info['itext'],
            info['licfor_decoded'])
        )

    return info, position, nbytes


def update_licinfo(fname, info, position, nbytes, expiration, description):
    byteorder = info['byteorder']
    with open(fname, 'rb') as f:
        data = f.read()

    size, offset = nbytes['expdate'], position['expdate']
    patch = expiration.encode()
    assert len(patch) == size
    data = data[:offset] + patch + data[offset+size:]

    size, offset = nbytes['exptime'], position['exptime']
    y, m, d = expiration[0:4], expiration[4:6], expiration[6:8]
    value = calendar.timegm(
        time.strptime('{}/{}/{}'.format(d, m, y), '%d/%m/%Y'))
    patch = value.to_bytes(size, byteorder=byteorder)
    assert len(patch) == size
    data = data[:offset] + patch + data[offset+size:]

    if description is not None:
        size, offset = nbytes['licfor'], position['licfor']
        description += '\n'
        lst = list(description.encode())
        u = info['issuetime']
        for i in range(len(lst)):
            u = u >> 1 | ((u & 1) << 31)
            lst[i] ^= u & 255
        patch = bytes(lst)+b'\0'*(size-len(lst))
        assert len(patch) == size
        data = data[:offset] + patch + data[offset+size:]

        size, offset = nbytes['l4len'], position['l4len']
        patch = len(lst).to_bytes(size, byteorder=byteorder)
        assert len(patch) == size
        data = data[:offset] + patch + data[offset+size:]

    with open(fname, 'wb') as f:
        f.write(data)


if __name__ == '__main__':
    if len(sys.argv) not in (2, 3, 4):
        print('Usage: {} <executable> [expiration] [descritpion]'.format(
            sys.argv[0]))
        sys.exit(1)

    executable = sys.argv[1]
    expiration, description = None, None
    if len(sys.argv) > 2:
        expiration = sys.argv[2]
        assert expiration.isnumeric()
        assert len(expiration) == 8
        assert expiration.startswith('20')
    if len(sys.argv) > 3:
        description = sys.argv[3]
        assert len(description) <= MAX_DESCLEN

    print('Before:')
    info, position, nbytes = read_licinfo(executable)
    if expiration is not None:
        print('After:')
        update_licinfo(
            executable, info,
            position, nbytes,
            expiration, description
        )
        read_licinfo(executable)
