" if exists('g:loaded_tokenize') || &compatible
"   finish
" endif
" let g:loaded_tokenize = 1

function! s:tokenize(...) range abort
  if a:lastline - a:firstline > 0 && a:0 > 1
    echoerr 'Range and file arguments are mutually exclusive'
  endif
  if a:0 == 3
    return call('tokenize#main', a:000)
  elseif a:0 == 2
    return call('tokenize#main', [a:1, '<stdout>', a:2])
  else
    echoerr 'Tokenize take 2-3 arguments'
  endif
endfunction

command! -bang -nargs=+ -range -complete=file Tokenize <line1>,<line2>call s:tokenize(<f-args>, <bang>0)
command! -nargs=1 -complete=file TokenizeDiff call tokenize#test#capture_tokenize(<f-args>)
