python3 <<EOF
import tokenize
def _py_tokenize(path):
    with open(path, 'rb') as f:
        try:
            return list(tokenize.tokenize(f.__next__))
        except (IndentationError, tokenize.TokenError, SyntaxError) as e:
            return e.__class__.__name__
EOF

" Return a list of tokens by tokenize.py or string of Exception name.
function! tokenize#test#py_tokenize(path) abort
  return py3eval(printf('_py_tokenize("%s")', a:path))
endfunction

" Return a list of tokens by tokenize.vim or string of Exception name
" or error(<VimError>) when it crashed.
function! tokenize#test#vim_tokenize(path) abort
  try
    let lst = tokenize#list(a:path, 0)
    return lst
  catch '^Vim'
    return substitute(v:exception, 'Vim(\w\+): \(.*\)', 'error(\1)', 'g')
  catch '^\(IndentationError\|TokenError\|SyntaxError\):'
    return substitute(v:exception, '^\(.\{-1,}Error\):.*', '\1', 'g')
  endtry
endfunction

" Test tokenize.vim against its python counterpart. Return true if their
" outputs are the same.
function! tokenize#test#against(path) abort
  return tokenize#test#py_tokenize(a:path) == tokenize#test#vim_tokenize(a:path)
endfunction

" Turn each item in lst into a string.
function! s:stringify(lst)
  return map(a:lst, 'tokenize#tuple_as_string(v:val)')
endfunction

" Setup a buffer for displaying output. Code came from plug.vim.
function! s:setup_buffer(output)
  call append(0, a:output)
  setlocal buftype=nofile bufhidden=wipe nobuflisted nolist noswapfile nowrap cursorline nomodifiable nospell
  diffthis
endfunction

" Run both versions of tokenize() and put their outputs in two diffmode
" buffer, side by side.
" This is useful for identifying bugs in tokenize.vim.
function! tokenize#test#capture_tokenize(path) abort
  tabnew
  call s:setup_buffer(s:stringify(tokenize#test#py_tokenize(a:path)))
  vnew
  call s:setup_buffer(s:stringify(tokenize#test#vim_tokenize(a:path)))
  execute 'f' 'TokenizeDiff'
  nnoremap <buffer> q :tabclose<CR>
endfunction
