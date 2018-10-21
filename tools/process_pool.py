'''Can we use concurrent.futures.ThreadPoolExecutor in Vim?'''

import concurrent.futures
import time
import vim

def task(n):
    return [int(x) for x in vim.eval('range(%d)' % n)]

def vim_tokenize(path):
    return vim.eval('tokenize#helper#vim_tokenize(%r)' % path)

def throw_task():
    vim.command('throw 1')

def test_concurrent():
    futures=[]
    path='./test/json.py'
    with concurrent.futures.ThreadPoolExecutor(4) as executor:
        for i in range(4):
            futures.append(executor.submit(vim_tokenize, path))
        for fu in futures:
            for r in fu.result():
                print(r)

def main():
    test_concurrent()

if __name__ == '__main__':
    main()
    # print(concurrent)

