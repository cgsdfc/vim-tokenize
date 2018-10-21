python3 <<EOF
import tokenize
def _py_tokenize(path):
    with open(path, 'rb') as f:
        try:
            return list(tokenize.tokenize(f.__next__))
        except (IndentationError, tokenize.TokenError) as e:
            return e.__class__.__name__
EOF

" Return a list of tokens by tokenize.py or string of Exception name.
function! tokenize#test#py_tokenize(path) abort
  return py3eval(printf('_py_tokenize("%s")', a:path))
endfunction

" Return a list of tokens by tokenize.vim or string of Exception name
" or error(<VimError>) when it crashed.
function! tokenize#test#vim_tokenize(path) abort
  let tknr = tokenize#FromFile(a:path)
  let lst = []
  while 1
    try
      call add(lst, tknr.GetNextToken())
    catch '^Vim'
      return substitute(v:exception, 'Vim(\w\+): \(.*\)', 'error(\1)', 'g')
    catch '^\(IndentationError\|TokenError\):'
      return substitute(v:exception, '^\(IndentationError\|TokenError\):.*', '\1', 'g')
    catch 'StopIteration'
      return lst
    endtry
  endwhile
endfunction

" Test tokenize.vim against its python counterpart. Return true if their
" outputs are the same.
function! tokenize#test#against(path) abort
  return tokenize#test#py_tokenize(a:path) == tokenize#test#vim_tokenize(a:path)
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
