'''Test tokenize.vim on a bunch of source files using
tokenize.py as reference.
'''

import subprocess
import tempfile
import tokenize
import os
import vim

def do_tokenize_vim(filename):
    _, output = tempfile.mkstemp()
    cmd = f"vim -c 'Tokenize! {filename} {output}' -c qall"
    returncode = s.system(cmd)
    assert returncode == 0
    return output

def do_tokenize_py(filename):
    _, output = tempfile.mkstemp()

if __name__ == '__main__':
