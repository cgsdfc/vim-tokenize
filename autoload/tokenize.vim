let s:LookupTable = tokenize#lookup#Table
let s:TAB_SIZE = 8
let s:TokenValue = tokenize#token#Value
let s:TokenName = tokenize#token#Name
let s:AllStringPrefixes = tokenize#token#AllStringPrefixes
let s:ExactType = tokenize#token#ExactType
let s:__file__ = expand('<sfile>')

function! s:regex(str) abort
  return '\m\C'.a:str
endfunction

function! s:lgroup(list_) abort
  return '\%('.join(a:list_, '\|').'\)'
endfunction

function! s:cgroup(...) abort
  return '\('.join(a:000, '\|').'\)'
endfunction

function! s:group(...) abort
  return '\%('.join(a:000, '\|').'\)'
endfunction

function! s:maybe(...) abort
  return call('s:group', a:000).'\='
endfunction

function! s:TokenInfo(type, string, start_, end_, line)
  return [a:type, a:string, a:start_, a:end_, a:line]
endfunction

let s:cookie = s:regex("^[ \t\f]*#.\\{-}coding[:=][ \t]*\\([[:alnum:]-.]\\+\\)")
let s:Blank = s:regex("^[ \t\f]*\\%([#\r\n]\\|$\\)")

let s:Whitespace = s:regex("[ \f\t]*")
let s:Comment = s:regex("#[^\r\n]*")
let s:Name = s:regex('\w\+')

let s:Hexnumber = s:regex('0[xX]\%(_\=[0-9a-fA-F]\)\+')
let s:Binnumber = s:regex('0[bB]\%(_\=[01]\)\+')
let s:Octnumber = s:regex('0[oO]\%(_\=[0-7]\)\+')
let s:Decnumber = s:regex('\%(0\%(_\=0\)*\|[1-9]\%(_\=[0-9]\)*\)')
let s:Intnumber = s:group(s:Hexnumber,s:Binnumber,s:Octnumber,s:Decnumber)

let s:Exponent = s:regex('[eE][-+]\=[0-9]\%(_\=[0-9]\)*')
let s:Pointfloat = s:group(s:regex('[0-9]\%(_\=[0-9]\)*\.\%([0-9]\%(_\=[0-9]\)*\)\='),
      \ s:regex('\.[0-9]\%(_\=[0-9]\)*')).s:maybe(s:Exponent)
let s:Expfloat = s:regex('[0-9]\%(_\=[0-9]\)*'.s:Exponent)
let s:Floatnumber = s:group(s:Pointfloat, s:Expfloat)
let s:Imagnumber = s:group(s:regex('[0-9]\%(_\=[0-9]\)*[jJ]'),s:Floatnumber.'[jJ]')
let s:Number = s:group(s:Imagnumber,s:Floatnumber,s:Intnumber)

let s:Single = s:regex('[^''\\]*\%(\\.[^''\\]*\)*''')
let s:Double = s:regex('[^"\\]*\%(\\.[^"\\]*\)*"')
let s:Single3 = s:regex('[^''\\]*\%(\%(\\.\|''\%(''''\)\@!\)[^''\\]*\)*''''''')
let s:Double3 = s:regex('[^"\\]*\%(\%(\\.\|"\%(""\)\@!\)[^"\\]*\)*"""')
let s:StringPrefix = s:regex(s:lgroup(s:AllStringPrefixes))
let s:Triple = s:group(s:StringPrefix."'''", s:StringPrefix.'"""')

let s:Operator = s:regex(s:group('\*\*=\=', '>>=\=', '<<=\=', '!=',
            \ '//=\?', '->',
            \ '[+\-*/%&@|^=<>]=\=',
            \ '\~'))

let s:Bracket = s:regex('[][(){}]')
let s:Special = s:regex(s:group("\n", '\.\.\.', '[:;.,@]'))
let s:Funny = s:group(s:Operator,s:Bracket,s:Special)

" First (or only) line of ' or " string.
let s:ContStr = s:group(s:StringPrefix."'[^'\n\\\\]*\\%(\\\\.[^'\n\\\\]*\\)*"
            \ .s:group("'", "\\\\\n"),
            \ s:StringPrefix."\"[^\"\n\\\\]*\\%(\\\\.[^\"\n\\\\]*\\)*"
            \ .s:group('"', "\\\\\n"))
let s:PseudoExtras = s:group("\\\\\n\\|\\%$", s:Comment, s:Triple)
let s:PseudoToken = '^'.s:Whitespace.s:cgroup(
      \ s:PseudoExtras,
      \ s:Number,
      \ s:Funny,
      \ s:ContStr,
      \ s:Name)
let tokenize#PseudoToken = s:PseudoToken

let s:endpats = {}
for s:prefix in s:AllStringPrefixes
    let s:endpats[s:prefix."'"] = s:Single
    let s:endpats[s:prefix.'"'] = s:Double
    let s:endpats[s:prefix."'''"] = s:Single3
    let s:endpats[s:prefix.'"""'] = s:Double3
endfor

let s:single_quoted = {}
let s:triple_quoted = {}
for s:t in s:AllStringPrefixes
  let s:single_quoted[s:t.'"'] = 1
  let s:single_quoted[s:t."'"] = 1
  let s:triple_quoted[s:t.'"""'] = 1
  let s:triple_quoted[s:t."'''"] = 1
endfor

function! tokenize#scriptdict()
  return s:
endfunction

function! s:decode(str, encoding) abort
  return iconv(a:str, a:encoding, 'UTF-8') . "\n"
endfunction

function! tokenize#GetNextToken() dict abort
  if self.error_or_end
    throw 'StopIteration'
  endif

  while 1
    if self.end_of_input
      if self.stashed isnot 0
        let [tok, self.stashed] = [self.stashed, 0]
        return tok
      endif
      if len(self.indents) == 1
        let self.error_or_end = 1
        return s:TokenInfo(s:TokenValue.ENDMARKER, '', [self.lnum, 0], [self.lnum, 0], '')
      else
        unlet self.indents[-1]
        return s:TokenInfo(s:TokenValue.DEDENT, '',  [self.lnum, 0], [self.lnum, 0], '')
      endif
    endif

    " detect indent/dedent
    if self.cur_indent < self.indents[-1]
      if index(self.indents, self.cur_indent) < 0
        call self._on_error('IndentationError',
              \ "unindent does not match any outer indentation level")
      endif
      unlet self.indents[-1]
      if self.async_def && self.async_def_indent >= self.indents[-1]
        let self.async_def = 0
        let self.async_def_nl = 0
        let self.async_def_indent = 0
      endif
      let tok = s:TokenInfo(s:TokenValue.DEDENT, '',
            \ [self.lnum, self.cpos],
            \ [self.lnum, self.cpos], self.line)
      let [tok, self.stashed] = [self.stashed, tok]
      return tok
    endif

    " if self.async_def && self.async_def_nl &&
    "       \ self.async_def_indent >= self.indents[-1]
    "   let self.async_def = 0
    "   let self.async_def_nl = 0
    "   let self.async_def_indent = 0
    " endif

    if self.contstr || self.pos >= self.max
      if self.lnum >= self.buffer_size
        let self.end_of_input = 1
        let self.line = ''
      else
        let self.line = s:decode(self.buffer_[self.lnum], self.encoding)
      endif
      let self.lnum += 1
      let [self.pos, self.max] = [0, len(self.line)]
      let [self.cpos, self.cmax] = [0, strchars(self.line)]

      if self.contstr
        if self.end_of_input
          call self._on_error('TokenError', 'EOF in multi-line string')
        endif
        let endmatch = matchlist(self.line, endprog)
        if !empty(endmatch)     " continued string ends
          let self.pos = len(endmatch[0])
          let self.cpos = strchars(endmatch[0])
          let end_ = self.pos
          call add(contstr, self.line[:end_-1])
          call add(contline, self.line)
          let self.contstr = 0
          let self.needcont = 0
          let tok = s:TokenInfo(s:TokenValue.STRING,
                \ join(contstr, ''), strstart,
                \ [self.lnum, self.cpos], join(contline, ''))
          let [tok, self.stashed] = [self.stashed, tok]
          return tok
        elseif self.needcont && self.line[self.max-2:] != "\\\n"
          let self.contstr = 0
          call add(contstr, self.line)
          let tok = s:TokenInfo(s:TokenValue.ERRORTOKEN,
                \ join(contstr, ''), strstart,
                \ [self.lnum, self.cmax], join(contline, ''))
          let [tok, self.stashed] = [self.stashed, tok]
          return tok
        else
          call add(contstr, self.line)
          call add(contline, self.line)
          continue
        endif
      elseif self.parenlev == 0 && !self.continued " new statement
        if self.end_of_input
          continue
        endif
        if self.line =~ s:Blank
          let self.blank = 1
        else
          let column = 0
          while self.pos < self.max
            if self.line[self.pos] == ' '
              let column += 1
            elseif self.line[self.pos] == "\t"
              let column = (column / s:TAB_SIZE + 1) * s:TAB_SIZE
            elseif self.line[self.pos] == "\f"
              let column = 0
            else
              break
            endif
            let self.cpos += 1
            let self.pos += 1
          endwhile
          let self.cur_indent = column
          if column > self.indents[-1]
            call add(self.indents, column)
            let tok = s:TokenInfo(s:TokenValue.INDENT,
                  \ self.line[:self.pos - 1],
                  \ [self.lnum, 0], [self.lnum, self.cpos], self.line)
            let [tok, self.stashed] = [self.stashed, tok]
            return tok
          elseif column < self.indents[-1]
            continue " jump to the code that handle dedent
          endif
        endif
      else          " continued statement
        if self.end_of_input
          call self._on_error('TokenError', 'EOF in mult-line statement')
        endif
        let self.continued = 0
      endif
    endif

    while self.pos < self.max
      let psmat = matchlist(self.line, s:PseudoToken, self.pos)
      if empty(psmat)
        let tok = s:TokenInfo(s:TokenValue.ERRORTOKEN, self.line[self.pos],
              \ [self.lnum, self.cpos],
              \ [self.lnum, self.cpos + 1], self.line)
        let self.pos += 1
        let self.cpos += 1
        let [tok, self.stashed] = [self.stashed, tok]
        return tok
      endif

      let entire = psmat[0]
      let token = psmat[1]
      let self.pos += len(entire)
      let self.cpos += strchars(entire)
      if empty(token)
        continue
      endif
      let start_ = self.pos - len(token)
      let end_ = self.pos
      let spos = [self.lnum, self.cpos - strchars(token)]
      let epos = [self.lnum, self.cpos]
      let initial = token[0]

      if initial =~ '[0-9]' ||
            \ (initial == '.' && token != '.' && token != '...')
        let tok = s:TokenInfo(s:TokenValue.NUMBER, token, spos, epos, self.line)
      elseif initial == "\n"
        if self.parenlev > 0 || self.blank
          let self.blank = 0
          let tok = s:TokenInfo(s:TokenValue.NL, token, spos, epos, self.line)
        else
          let tok = s:TokenInfo(s:TokenValue.NEWLINE, token, spos, epos, self.line)
          if self.async_def
            let self.async_def_nl = 1
          endif
        endif
      elseif initial == '#'
        let tok = s:TokenInfo(s:TokenValue.COMMENT, token, spos, epos, self.line)
      elseif has_key(s:triple_quoted, token)         " check for triple_quoted
        let endprog = s:endpats[token]
        let endmatch = matchlist(self.line, endprog, self.pos)
        if !empty(endmatch)
          " all in one line
          let self.pos += len(endmatch[0])
          let self.cpos += strchars(endmatch[0])
          let token = self.line[start_: self.pos-1]
          let tok = s:TokenInfo(s:TokenValue.STRING,
                \ token, spos, [self.lnum, self.cpos], self.line)
        else " multiple lines
          let strstart = spos
          let contstr = [self.line[start_:]]
          let contline = [self.line]
          let self.contstr = 1
          break
        endif
      elseif (has_key(s:single_quoted, initial) ||
            \ has_key(s:single_quoted, token[:1]) ||
            \ has_key(s:single_quoted, token[:2]))
        if self.line[end_ - 1] == "\n"
          let strstart = spos
          let endprog = get(s:endpats, initial,
                \ get(s:endpats, token[1],
                \ get(s:endpats, token[2])))
          let self.needcont = 1
          let self.contstr = 1
          let contstr = [self.line[start_:]]
          let contline = [self.line]
          break
        else
          let tok = s:TokenInfo(s:TokenValue.STRING, token, spos, epos, self.line)
        endif
      elseif initial =~ '[a-zA-Z_]' " isidentifier()
        if token =~# '\m\c^\(async\|await\)$' && self.async_def
          let tok = s:TokenInfo(token == 'async' ?
                \ s:TokenValue.ASYNC : s:TokenValue.AWAIT,
                \ token, spos, epos, self.line)
        else
          let tok = s:TokenInfo(s:TokenValue.NAME, token, spos, epos, self.line)
          if token ==# 'def' &&
                \ self.stashed[0] == s:TokenValue.NAME &&
                \ self.stashed[1] ==# 'async'
            let self.async_def = 1
            let self.async_def_indent = self.cur_indent
            let self.stashed[0] = s:TokenValue.ASYNC
          endif
        endif
      elseif initial == '\'
        let self.continued = 1
        continue
      else
        if initial =~ '[(\[{]'
          let self.parenlev += 1
        elseif initial =~ '[)}\]]'
          let self.parenlev -= 1
        endif
        let type = self.exact && has_key(s:ExactType, token) ?
              \ s:ExactType[token] : s:TokenValue.OP
        let tok = s:TokenInfo(type, token, spos, epos, self.line)
      endif
      let [tok, self.stashed] = [self.stashed, tok]
      return tok
    endwhile
  endwhile
endfunction

function! s:detect_encoding() dict abort
  let default = 'utf-8'
  if self.buffer_size == 0 " empty file
    return default
  endif
  let first_ = self.buffer_[0]
  let encoding = s:find_cookie(first_, self.filename)
  if encoding isnot 0
    return encoding
  endif
  if first_ !~ s:Blank
    return default
  endif
  if self.buffer_size < 2
    return default
  endif
  let second = self.buffer_[1]
  let encoding = s:find_cookie(second, self.filename)
  if encoding isnot 0
    return encoding
  endif
  return default
endfunction

function! s:find_cookie(line, filename) abort
  let match = matchlist(a:line, s:cookie)
  if empty(match)
    return 0
  endif
  let encoding = s:get_normal_name(match[1])
  if has_key(s:LookupTable, encoding)
    return s:LookupTable[encoding]
  endif
  throw printf('SyntaxError: unknown encoding for "%s": %s', a:filename, encoding)
endfunction

function! s:get_normal_name(orig_enc)
  let enc = substitute(tolower(a:orig_enc[:11]), '_', '-', 'g')
  if enc =~# '^utf-8\(-.*\|$\)'
    return 'utf-8'
  endif
  if enc =~# '^\(latin-1\|iso-8859-1\|iso-latin-1\)\(-.*\|$\)'
    return 'iso-8859-1'
  endif
  return a:orig_enc
endfunction

let s:Tokenizer = {
      \ 'getline': 0,
      \ 'end_of_input': 0,
      \ 'filename': '',
      \ 'blank': 0,
      \ 'line': '',
      \ 'async_def': 0,
      \ 'async_def_indent': 0,
      \ 'async_def_nl': 0,
      \ 'async_stashed': 0,
      \ 'contstr': 0,
      \ 'needcont': 0,
      \ 'continued': 0,
      \ 'stashed': 0,
      \ 'pos': 0,
      \ 'cpos': 0,
      \ 'cmax': 0,
      \ 'max': 0,
      \ 'cur_indent': 0,
      \ 'error_or_end': 0,
      \ 'buffer_': 0,
      \ 'buffer_size': 0,
      \ 'lnum': 0,
      \ 'parenlev': 0,
      \ 'indents': [0],
      \ 'encoding': '',
      \ 'exact': 0,
      \ 'GetNextToken': function('tokenize#GetNextToken'),
      \ 'detect_encoding': function('s:detect_encoding'),
      \}

function! s:Tokenizer._on_error(type, msg) abort
  let self.error_or_end = 1
  let msg = printf('%s: %s:%d:%d: %s',
        \ a:type, self.filename, self.lnum, self.cpos, a:msg)
  throw msg
endfunction

function! tokenize#FromFile(path)
  let tknr = deepcopy(s:Tokenizer)
  let tknr.buffer_ = readfile(a:path)
  let tknr.buffer_size = len(tknr.buffer_)
  let tknr.filename = a:path
  let encoding = tknr.detect_encoding()
  let tknr.stashed = s:TokenInfo(s:TokenValue.ENCODING,
        \ encoding, [0, 0], [0, 0], '')
  return tknr
endfunction

let s:escapes = {
      \ "\b": '\b',
      \ "\e": '\e',
      \ "\f": '\f',
      \ "\n": '\n',
      \ "\r": '\r',
      \ "\t": '\t',
      \ "'": '\''',
      \ "\\": '\\',
      \ '"': '\"',
      \}

function! tokenize#dump(str)
  " If only has single, use double quote, "'".
  " If only has double, use single quote, '"'.
  " If has both, use single quote, escape single quotes, '\'"'.
  if a:str =~ '"' && a:str !~ "'"
    return printf("'%s'", substitute(a:str, "[\001-\037\\\\]",
          \  '\=get(s:escapes, submatch(0))', 'g'))
  elseif a:str =~ "'" && a:str !~ '"'
    return printf('"%s"', substitute(a:str, "[\001-\037\\\\]",
          \  '\=get(s:escapes, submatch(0))', 'g'))
  else
    return printf("'%s'", substitute(a:str, "[\001-\037\\\\']",
          \  '\=get(s:escapes, submatch(0))', 'g'))
  endif
endfunction

function! tokenize#tuple_as_dict(tuple) abort
  return {
        \ 'type': a:tuple[0],
        \ 'string': a:tuple[1],
        \ 'start': a:tuple[2],
        \ 'end': a:tuple[3],
        \ 'line': a:tuple[4]
        \ }
endfunction

function! tokenize#tuple_as_string(tuple) abort
  let token_range = call('printf', ['%d,%d-%d,%d:']+a:tuple[2]+a:tuple[3])
  return printf('%-20s%-15s%-15S', token_range,
        \ s:TokenName[a:tuple[0]], tokenize#dump(a:tuple[1]))
endfunction

function! tokenize#main(path, out, exact)
  try
    let tknr = tokenize#FromFile(a:path)
    let tknr.exact = a:exact
    let val = []
    while 1
      let tk = tknr.GetNextToken()
      call add(val, tokenize#tuple_as_string(tk))
    endwhile
  catch 'StopIteration'
    if a:out ==# '<stdout>'
      echo join(val, "\n")
    elseif a:out ==# '<string>'
      return join(val, "\n")
    else
      call writefile(val, a:out)
    endif
  catch
    echohl ERROR
    echo v:exception
    echohl NONE
    return
  endtry
endfunction

