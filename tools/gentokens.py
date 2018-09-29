#!/usr/bin/env python3
import re
import tokenize

__version__ = '0.0.5'

class TokenGen:
    AU_PATH=re.compile(r'.*/?autoload/(.*)\.vim')

    def __init__(self, file_):
        self.file_=file_
        self.token_list=[(name,val) for name,val in vars(tokenize).items()
                if name.isupper() and isinstance(val, int)]
        ns=self.make_ns(file_)
        self.token_var=f'{ns}#Value'
        self.tok_name_var=f'{ns}#Name'
        self.exact_var=f'{ns}#ExactType'
        self.all_string_prefixes_var=f'{ns}#AllStringPrefixes'

    def make_ns(self, file_):
        '''Return the autoload namespace given ``file_``.
        autoload/tokenize/token.vim -> tokenize#token
        '''
        mat=self.AU_PATH.match(file_.name)
        return mat.group(1).replace('/', '#')

    def gen(self):
        with self.file_ as out:
            out.write(f'" Generated by gentokens.py (Version {__version__}). Do not edit.\n\n')
            # Token values
            out.write(f'let {self.token_var}={{}}\n')
            for name,val in self.token_list:
                out.write(f'let {self.token_var}.{name}={val}\n')
            out.write('\n')

            # Token names
            out.write(f'let {self.tok_name_var}={{}}\n')
            for name,val in self.token_list:
                out.write(f'let {self.tok_name_var}[{val}]={name!r}\n')
            out.write('\n')

            # Exact token types. Maping operator strings to their values
            out.write(f'let {self.exact_var}={{}}\n')
            for op,val in tokenize.EXACT_TOKEN_TYPES.items():
                out.write(f'let {self.exact_var}[{op!r}]={val}\n')
            out.write('\n')

            # all_string_prefixes
            out.write(f'let {self.all_string_prefixes_var}=[')
            out.write(', '.join(f'{s!r}' for s in tokenize._all_string_prefixes()))
            out.write(']\n')

def main():
    import argparse
    import sys
    p = argparse.ArgumentParser(
            description='Generate VimL scripts for python tokens (compatible with module tokenize)')
    p.add_argument('path',
            nargs=1,
            type=argparse.FileType('w'),
            help='path to the generated token file')
    args = p.parse_args()
    return TokenGen(args.path[0]).gen()

if __name__ == '__main__':
    main()
