import os
import subprocess
import multiprocessing
import concurrent.futures

'''
Test tokenize.vim on a bunch of python files.
'''

def test_one(path):
    val = int(subprocess.check_output(
        ['vim', '--servername', 'TOKEN', '--remote-expr', 'tokenize#test#against(%r)' % path]))
    if not val:
        print('error:', path)
    else:
        print('ok:', path)

def run_tests(dir, n):
    futures=[]
    with concurrent.futures.ThreadPoolExecutor(n) as executor:
        for dirpath,_,filenames in os.walk(dir):
            for filename in filenames:
                path=os.path.join(dirpath, filename)
                futures.append(executor.submit(test_one, path))

def main():
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dir', type=str, required=True,
            help='Directory to look for python files')
    parser.add_argument('--workers', type=int, default=4,
            help='Threads to use for test running')
    args = parser.parse_args()
    return run_tests(args.dir, args.workers)


if __name__ == '__main__':
    main()
