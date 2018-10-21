let s:__file__ = expand('<sfile>')

python3 <<EOF
import sys
import vim
import os
__file__ = vim.eval('s:__file__')
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))
from tools.test import test_tokenize, run_and_diff
EOF

function! tokenize#test#test_tokenize(dir_) abort
  return py3eval('test_tokenize()')
endfunction

function! tokenize#test#vim_tokenize(path) abort
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

function! tokenize#test#run_and_diff(path) abort
  let files = py3eval('run_and_diff()')
  let [vout, pout] = files
  execute 'tabnew' vout
  execute 'diffsplit' pout
  nnoremap q :tabclose
  for out in files
    call delete(out)
  endfor
endfunction
function! tokenize#test#bytes_repr(bytes) abort
  let bytes = map(range(len(a:bytes)), 'char2nr(a:bytes[v:val])')
  return join(map(bytes, 'v:val < 256 ? nr2char(v:val) : printf(''\x%x'', v:val)'), '')
endfunction

function! tokenize#test#encode(str, encoding) abort
  let bytes = iconv(a:str, 'UTF-8', a:encoding)
  return tokenize#test#bytes_repr(bytes)
endfunction

function! tokenize#test#py_encode(string, enc) abort
  return py3eval(printf("'%s'.encode('%s')", a:string, a:enc))
endfunction

function! tokenize#test#py_decode(string, enc) abort
  return py3eval(printf("b'%s'.decode('%s')", a:string, a:enc))
endfunction
