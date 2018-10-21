'''Can we use concurrent.futures.ThreadPoolExecutor in Vim?'''

import concurrent.futures
import time
import vim

def task(n):
    return [int(x) for x in vim.eval('range(%d)' % n)]

def test_concurrent():
    futures=[]
    with concurrent.futures.ThreadPoolExecutor(4) as executor:
        for i in range(100):
            futures.append(executor.submit(task, 100))
        for fu in futures:
            print(fu.result())

def main():
    test_concurrent()

if __name__ == '__main__':
    main()
