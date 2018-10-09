'''
Test tokenize.vim against tokenize.py, run by :TestTokenize
'''
import logging
import tokenize
import vim
import os

def vim_tokenize(path):
    'Tokenize a file using vim impl and convert the result to TokenInfo'
    try:
        return [tokenize.TokenInfo(int(tok[0]), tok[1],
            tuple(map(int, tok[2])),
            tuple(map(int, tok[3])), tok[4])
            for tok in vim.eval('tokenize#helper#vim_tokenize(%r)' % path)]
    except Exception as e:
        print(e)

def py_tokenize(path):
    with open(path, 'rb') as f:
        return list(tokenize.tokenize(f.__next__))

def diff_tokenize(path):
    '''
    Run 2 versions of tokenize() on path and compare their results
    '''
    return vim_tokenize(path) == py_tokenize(path)

def filenames_from_dir(dir_):
    '''
    Return all the py files under a directory, recursively
    '''
    for dirpath,_,filenames in os.walk(dir_):
        for fn in filenames:
            if fn.endswith('.py'):
                yield os.path.join(dirpath, fn)

def do_test(files, logger):
    '''
    Run tests on files, log the failures
    '''
    fails = 0
    for i, path in enumerate(files, 1):
        ok = diff_tokenize(path)
        if not ok:
            logger.error(path)
            fails += 1
    logger.info('Run %d, Failed %d', i, fails)
    return fails

def test_tokenize(dir_):
    '''
    Test tokenize() using all py files in dir_
    '''
    logger = logging.getLogger('test_tokenize')
    logger.setLevel(logging.DEBUG)
    dest = os.path.abspath('./test/%s.log' % os.path.basename(dir_.strip(os.path.sep)))
    fh = logging.FileHandler(dest, mode='w')
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    fh.setFormatter(formatter)
    fh.setLevel(logging.DEBUG)
    logger.addHandler(fh)
    files = filenames_from_dir(dir_)
    return diff_batch(files, logger)
