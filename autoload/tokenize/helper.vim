python3 <<EOF
import tokenize
import vim
import glob
import os

def do_tokenize():
    with open(vim.eval('a:path'), 'rb') as f:
        return list(tokenize.tokenize(f.__next__))

def vim_tokenize(path):
    'Tokenize a file using vim impl and convert the result to TokenInfo'
    for tok in vim.eval('tokenize#helper#vim_tokenize(%r)' % path):
        yield tokenize.TokenInfo(int(tok[0]), tok[1],
            tuple(map(int, tok[2])),
            tuple(map(int, tok[3])), tok[4])

def py_tokenize(path):
    with open(path, 'rb') as f:
        return list(tokenize.tokenize(f.__next__))

def diff_tokenize(path):
    '''Run 2 versions of tokenize() on path and return their diff in a list
    '''
    # print(list(vim_tokenize(path)))
    return list(vim_tokenize(path)) == py_tokenize(path)

def diff_batch(dir_):
    pat = os.path.join(dir_, '*.py')
    files = glob.glob(pat)
    fails = 0
    for path in files:
        ok = diff_tokenize(path)
        print('%s: %s' % (path, 'OK' if ok else 'Failure'))
        fails += not ok
    print('Run %d, Failed %d' % (len(files), fails))
    return fails, files

EOF

function! tokenize#helper#vim_tokenize(path) abort
  let tknr = tokenize#FromFile(a:path)
  let lst = []
  while 1
    try
      call add(lst, tknr.GetNextToken())
    catch 'StopIteration'
      return lst
    endtry
  endwhile
endfunction

function! tokenize#helper#py_tokenize(path) abort
  return py3eval('do_tokenize()')
endfunction

function! tokenize#helper#diff(path) abort
  let a = tokenize#helper#py_tokenize(a:path)
  let b = tokenize#helper#vim_tokenize(a:path)
  return [a, b, a == b]
endfunction

function! tokenize#helper#glob_diff(dir) abort
  let logfile = tempname()
  let logger = tokenize#logging#get_logger(logfile)
  let logger.log_to_stderr = 1
  let inps = glob(printf('%s/*.py', a:dir), 0, 1)
  let fails = 0

  for inp in inps
    try
      let [a, b, rc] = tokenize#helper#diff(inp)
    catch
      call logger.info(inp)
    endtry
    if rc == 0
      call logger.info(inp)
      let fails += 1
    endif
  endfor
  call logger.info('Run diff on %d files, fails %d', len(inps), fails)
  return [logfile, fails]
endfunction
