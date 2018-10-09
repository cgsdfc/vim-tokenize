python3 <<EOF
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
    '''Run 2 versions of tokenize() on path and return their diff in a list
    '''
    return vim_tokenize(path) == py_tokenize(path)

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
        if not ok:
            logger.error(path)
        fails += not ok
    logger.info('Run %d, Failed %d', i, fails)

def test_tokenize(dir_):
    '''Test tokenize() using all py files in dir_'''
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

function! tokenize#helper#run_and_diff(path) abort
    let out = './out'
    let OUT = './OUT'
    call system('python3 -m tokenize -e '.a:path.' >'.OUT)
    call tokenize#main(a:path, out, 1)
    execute 'tabnew' out
    execute 'diffsplit' OUT
endfunction

let s:TokenValue=tokenize#token#Value
let s:TokenName=tokenize#token#Name
let s:PseudoToken=tokenize#PseudoToken

let s:LineScanner = {
      \ 'line': 0,
      \ 'pos': 0,
      \ 'cpos': 0,
      \ 'max': 0,
      \ }

function! s:LineScanner.GetNextToken() abort
  while 1
    if self.pos == self.max
      throw 'StopIteration'
    endif
    let psmat = matchlist(self.line, s:PseudoToken, self.pos)
    if empty(psmat)
      let self.pos += 1
      let self.cpos += 1
      return [s:TokenValue.ERRORTOKEN, self.line[self.pos-1], [self.pos-1, self.pos]]
    endif
    let entire = psmat[0]
    let token = psmat[1]
    let self.pos += len(entire)
    if empty(token)
      continue
    endif
    if token is "\n"
      return [s:TokenValue.NL, "\n", [self.pos, self.pos+1]]
    endif
    let loc_ = [self.pos-len(token), self.pos]
    return [s:TokenValue.OP, token, loc_]
  endwhile
endfunction

function! tokenize#helper#ScanLine(line) abort
  let lineScanner = deepcopy(s:LineScanner)
  let lineScanner.line = a:line
  let lineScanner.max = len(a:line)
  let out = []
  try
    while 1
      let val = lineScanner.GetNextToken()
      let loc_ = call('printf', ['%d,%d:']+val[2])
      let str = printf('%-20s%-15s%-15s', loc_, s:TokenName[val[0]],
            \ tokenize#dump(val[1]))
      Log str
    endwhile
  catch 'StopIteration'
    return out
  endtry
endfunction
