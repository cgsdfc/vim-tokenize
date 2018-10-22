'''
Generate ``tokenize#lookup#Table`` which maps normalized codecs name to
names recognized by iconv().
'''

import re
import sys
import subprocess
import os
import codecs
from pprint import pprint as pp

__version__ = '0.0.4'

def call_iconv_list():
    '''
    Invoke iconv if available, return the encoding names in a list
    '''
    res = subprocess.check_output(['iconv', '--list'])
    return [s.strip('/') for s in res.decode().split()]


def get_lookup_mapping(il):
    '''
    Return a lookup mapping m where acceptable names are mapped to iconv_name
    '''
    def normalize(name):
        name=re.sub(r'([A-Za-z]+)([0-9]+)', r'\1-\2', name)
        return re.sub('_', '-', name).lower()

    def iter_names(il):
        for name in il:
            try:
                codecs_name = codecs.lookup(name).name
                yield (normalize(codecs_name), name)
            except LookupError:
                continue
    return dict(iter_names(il))

def proccess_mapping(m):
    '''
    Process the mapping so that it is suitable for dump_vim_dict()
    '''

    return sorted(m.items())

def dump_vim_dict(ilist, out):
    '''
    Write the appropriate ilist to out (out should be tokenize/lookup.vim)
    '''
    out.write(f'" Generated by genlookup.py ({__version__}); Do not edit.\n\n')
    out.write('let tokenize#lookup#Table = {\n')
    for codecs_name, iconv_name in ilist:
        out.write(f'  \\ {codecs_name!r}: {iconv_name!r},\n')
    out.write('  \\}\n')

def main():
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('-o', '--output', dest='output',
            default=sys.stdout,
            type=argparse.FileType('w'), help='output file path')
    args = parser.parse_args()
    il = call_iconv_list()
    mapping = get_lookup_mapping(il)
    il = proccess_mapping(mapping)
    with args.output as out:
        return dump_vim_dict(il, out)


if __name__ == '__main__':
    sys.exit(main())
