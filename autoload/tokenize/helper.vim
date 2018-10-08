python3 <<EOF
import logging
import tokenize
import vim
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

def filenames_from_file(path):
    '''Return a list of paths read from ``path``'''
    with open(path) as f:
        return list(f.readlines())

def filenames_from_dir(dir_):
    '''Return all the py files under a directory, recursively'''
    for dirpath,_,filenames in os.walk(dir_):
        for fn in filenames:
            if fn.endswith('.py'):
                yield os.path.join(dirpath, fn)

def diff_batch(files, logger):
    fails = 0
    for i, path in enumerate(files, 1):
        ok = diff_tokenize(path)
        if ok:
            logger.info('%s: OK', path)
        else:
            logger.error('%s: Failure', path)
        fails += not ok
    logger.info('Run %d, Failed %d', i, fails)

def test_tokenize(dir_):
    '''Test tokenize() using all py files in dir_'''
    logger = logging.getLogger('test_tokenize')
    handler = logging.FileHandler('/home/cgsdfc/Vimscripts/vim-tokenize/test/tokenize.log')
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)
    logger.debug('py files from %s', dir_)
    files = filenames_from_dir(dir_)
    return diff_batch(files, logger)

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

function! tokenize#helper#run_and_diff(path) abort
    let out = './out'
    let OUT = './OUT'
    call system('python3 -m tokenize -e '.a:path.' >'.OUT)
    call tokenize#main(a:path, out, 1)
    execute 'tabnew' out
    execute 'diffsplit' OUT
endfunction
