let s:__file__ = expand('<sfile>')

python3 <<EOF
import sys
import vim
import os
__file__ = vim.eval('s:__file__')
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))
from tools.test import test_tokenize, run_and_diff
EOF

function! tokenize#helper#test_tokenize(dir_) abort
  return py3eval('test_tokenize()')
endfunction

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
  let files = py3eval('run_and_diff()')
  let [vout, pout] = files
  execute 'tabnew' vout
  execute 'diffsplit' pout
  nnoremap q :tabclose
  for out in files
    call delete(out)
  endfor
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
    let self.cpos += strchars(entire)
    if empty(token)
      continue
    endif
    if token is "\n"
      return [s:TokenValue.NL, "\n", [self.cpos, self.cpos+1]]
    endif
    let loc_ = [self.cpos-len(token), self.cpos]
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
