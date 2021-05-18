#!/usr/bin/env python3
from datetime import datetime, timedelta
from subprocess import check_output
from requests import get, post
from os import path
from time import time
import sys

AMPLKEY_URL = None
# AMPLKEY_URL = 'https://69vtnouiic.execute-api.us-east-1.amazonaws.com/prod/'
# AMPLKEY_URL = 'https://account.ampl.online/v1/amplkey/renew'
# AMPLKEY_URL = 'http://127.0.0.1:4000/v1/amplkey/renew'
CONFIG_URL = 'https://ampl.com/dl/fdabrandao/amplkey.conf.json'


def amplkey(licfile):
    try:
        last = float(open(licfile+'.timestamp', 'r').read())
        if time()-last <= 4*60:
            return True
    except:
        pass

    if AMPLKEY_URL is not None:
        urls = [AMPLKEY_URL]
    else:
        print('Request configuration:')
        response = get(CONFIG_URL)
        print('Satus code:', response.status_code)
        print('Response:', response.content.decode())
        if response.status_code != 200:
            return False
        config = response.json()
        urls = config['URLs']
    for url in urls:
        print('Request License from {}:'.format(url))
        req = {
            'fingerprint': check_output(['fingerprint', '-s']).decode(),
            'license': open(licfile, 'r').read(),
            'client': 'amplkey.py',
        }
        print('Request:', req)
        response = post(url, json=req)
        print('Satus code:', response.status_code)
        print('Response:', response.content.decode())
        if response.status_code == 200:
            res = response.json()
            if 'error' in res:
                print('Error:', res['error'])
                return False
            elif 'newlicense' in res:
                open(licfile, 'w').write(res['newlicense'])
                print('Wrote ampl.lic to {}'.format(licfile))
                open(licfile+'.timestamp', 'w').write(str(time()))
                return True
    return False


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print('Usage: {} <ampl.lic>'.format(sys.argv[0]))
        sys.exit(1)
    if not amplkey(sys.argv[1]):
        sys.exit(1)
