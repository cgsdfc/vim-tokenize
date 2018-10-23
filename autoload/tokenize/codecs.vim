" This file is intended to clear the encoding stuffs out of tokenize.vim

let s:regex = tokenize#regex#all()

" Detect encoding from the buffer.
function! tokenize#codecs#detect_encoding(buffer_, buffer_size, filename) abort
  let default = 'utf-8'
  if a:buffer_size == 0 " empty file
    return default
  endif
  let first_ = a:buffer_[0]
  let encoding = tokenize#codecs#find_cookie(first_, a:filename)
  if encoding isnot 0
    return encoding
  endif
  if first_ !~ s:regex.Blank
    return default
  endif
  if a:buffer_size < 2
    return default
  endif
  let second = a:buffer_[1]
  let encoding = tokenize#codecs#find_cookie(second, a:filename)
  if encoding isnot 0
    return encoding
  endif
  return default
endfunction

" Look for encoding declaration from line. We don't care about BOM
" and don't try to decode the line. Just look for a plausible cookie.
function! tokenize#codecs#find_cookie(line, filename) abort
  let match = matchlist(a:line, s:regex.Cookie)
  if empty(match)
    return 0
  endif
  let encoding = tokenize#codecs#get_normal_name(match[1])
  if has_key(g:tokenize#lookup#Table, encoding)
    return encoding
  endif
  throw printf('SyntaxError: unknown encoding for "%s": %s', a:filename, encoding)
endfunction

" Normalize orig_enc. All characters are lower case and _'s are replaced with
" -
function! tokenize#codecs#get_normal_name(orig_enc)
  let enc = substitute(tolower(a:orig_enc[:11]), '_', '-', 'g')
  if enc =~# '^utf-8'
    return 'utf-8'
  endif
  if enc =~# '^\(latin1\|iso88591\|isolatin1\)'
    return 'iso-8859-1'
  endif
  return a:orig_enc
endfunction

" Convert str from encoding to utf-8 adding tailing newline.
function! tokenize#codecs#decode(str, encoding) abort
  return iconv(a:str, a:encoding, 'UTF-8') . "\n"
endfunction
