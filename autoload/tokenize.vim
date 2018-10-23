let s:TAB_SIZE = 8
let s:TokenValue = tokenize#token#Value
let s:TokenName = tokenize#token#Name
let s:AllStringPrefixes = tokenize#token#AllStringPrefixes
let s:ExactType = tokenize#token#ExactType
let s:regex = tokenize#regex#all()

" Map all variations of beginning of a string to patterns
" of its ending part.
let s:endpats = {}
for s:prefix in s:AllStringPrefixes
  let s:endpats[s:prefix."'"] = s:regex.Single
  let s:endpats[s:prefix.'"'] = s:regex.Double
  let s:endpats[s:prefix."'''"] = s:regex.Single3
  let s:endpats[s:prefix.'"""'] = s:regex.Double3
endfor

" Keep all variations of single quotes and triple quotes.
let s:single_quoted = {}
let s:triple_quoted = {}
for s:t in s:AllStringPrefixes
  let s:single_quoted[s:t.'"'] = 1
  let s:single_quoted[s:t."'"] = 1
  let s:triple_quoted[s:t.'"""'] = 1
  let s:triple_quoted[s:t."'''"] = 1
endfor

function! s:TokenInfo(type, string, start_, end_, line)
  return [a:type, a:string, a:start_, a:end_, a:line]
endfunction

" The Tokenizer structure:
" end_of_input: input ends, no more bytes left to tokenize.
" filename: (maybe not absolute) path to the file being tokenized.
" blank: flag used to tell NL from NEWLINE in a blank (comment Whitespace only) line.
" line: current line.
" async_def: flag set when inside an `async def` block.
" async_def_indent: indent of the line that enters async def block, used to tell
" the leaving from an async def block.
" async_def_nl: currently unspecified.
" contstr: flag set when in a multi-line string (triple quoted or backslash
" newline).
" needcont: TODO
" continued: TODO
" stashed: One pending token.
" pos: current byte position in line.
" cpos: current character position in line.
" cmax: maximum character position in line.
" max: maximum byte position in line.
" cur_indent: current indent level used to track dedent popping.
" error_or_end: flag set when token stream ends or errored.
" buffer_: a list of lines.
" buffer_size: the size of buffer_.
" lnum: current line number.
" parenlev: current parenthesis level.
" indents: indent level stack.
" _encoding: iconv() specific encoding name.
" exact: flag set when exact type of OP should be used.
let s:Tokenizer = {
      \ 'end_of_input': 0,
      \ 'filename': '',
      \ 'blank': 0,
      \ 'line': '',
      \ 'async_def': 0,
      \ 'async_def_indent': 0,
      \ 'async_def_nl': 0,
      \ 'continued': 0,
      \ 'stashed': 0,
      \ 'pos': 0,
      \ 'max': 0,
      \ 'cpos': 0,
      \ 'cmax': 0,
      \ 'cur_indent': 0,
      \ 'error_or_end': 0,
      \ 'buffer_': 0,
      \ 'buffer_size': 0,
      \ 'lnum': 0,
      \ 'parenlev': 0,
      \ 'indents': [0],
      \ '_encoding': '',
      \ 'exact': 0,
      \}

" The main tokenizer function.
function! s:Tokenizer._tokenize() abort
  let is_contstr = 0
  let needcont = 0

  while 1
    if self.end_of_input
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
      return s:TokenInfo(s:TokenValue.DEDENT, '',
            \ [self.lnum, self.cpos],
            \ [self.lnum, self.cpos], self.line)
    endif

    " if self.async_def && self.async_def_nl &&
    "       \ self.async_def_indent >= self.indents[-1]
    "   let self.async_def = 0
    "   let self.async_def_nl = 0
    "   let self.async_def_indent = 0
    " endif

    if is_contstr || self.pos >= self.max
      if self.lnum >= self.buffer_size
        let self.end_of_input = 1
        let self.line = ''
      else
        let self.line = tokenize#codecs#decode(self.buffer_[self.lnum], self._encoding)
      endif
      let self.lnum += 1
      let [self.pos, self.max] = [0, len(self.line)]
      let [self.cpos, self.cmax] = [0, strchars(self.line)]

      if is_contstr
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
          return s:TokenInfo(s:TokenValue.STRING,
                \ join(contstr, ''), strstart,
                \ [self.lnum, self.cpos], join(contline, ''))
        elseif needcont && self.line[self.max-2:] != "\\\n"
          call add(contstr, self.line)
          return s:TokenInfo(s:TokenValue.ERRORTOKEN,
                \ join(contstr, ''), strstart,
                \ [self.lnum, self.cmax], join(contline, ''))
        else
          call add(contstr, self.line)
          call add(contline, self.line)
          continue
        endif
      elseif self.parenlev == 0 && !self.continued " new statement
        if self.end_of_input
          continue
        endif
        if self.line =~ s:regex.Blank
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
            return s:TokenInfo(s:TokenValue.INDENT,
                  \ self.line[:self.pos - 1],
                  \ [self.lnum, 0], [self.lnum, self.cpos], self.line)
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
      let psmat = matchlist(self.line, s:regex.PseudoToken, self.pos)
      if empty(psmat)
        let tok = s:TokenInfo(s:TokenValue.ERRORTOKEN, self.line[self.pos],
              \ [self.lnum, self.cpos],
              \ [self.lnum, self.cpos + 1], self.line)
        let self.pos += 1
        let self.cpos += 1
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
        return s:TokenInfo(s:TokenValue.NUMBER, token, spos, epos, self.line)
      elseif initial == "\n"
        if self.parenlev > 0 || self.blank
          let self.blank = 0
          return s:TokenInfo(s:TokenValue.NL, token, spos, epos, self.line)
        endif " NEWLINE
        if self.async_def
          let self.async_def_nl = 1
        endif
        return s:TokenInfo(s:TokenValue.NEWLINE, token, spos, epos, self.line)
      elseif initial == '#'
        return s:TokenInfo(s:TokenValue.COMMENT, token, spos, epos, self.line)
      elseif has_key(s:triple_quoted, token)         " check for triple_quoted
        let endprog = s:endpats[token]
        let endmatch = matchlist(self.line, endprog, self.pos)
        if !empty(endmatch)
          " all in one line
          let self.pos += len(endmatch[0])
          let self.cpos += strchars(endmatch[0])
          let token = self.line[start_: self.pos-1]
          return s:TokenInfo(s:TokenValue.STRING,
                \ token, spos, [self.lnum, self.cpos], self.line)
        else " multiple lines
          let strstart = spos
          let contstr = [self.line[start_:]]
          let contline = [self.line]
          let is_contstr = 1
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
          let needcont = 1
          let is_contstr = 1
          let contstr = [self.line[start_:]]
          let contline = [self.line]
          break
        else
          return s:TokenInfo(s:TokenValue.STRING, token, spos, epos, self.line)
        endif
      elseif initial =~ '[a-zA-Z_]' " isidentifier()
        if token =~# '\m\c^\(async\|await\)$' && self.async_def
          return s:TokenInfo(token == 'async' ?
                \ s:TokenValue.ASYNC : s:TokenValue.AWAIT,
                \ token, spos, epos, self.line)
        endif
        if token ==# 'def' &&
              \ self.stashed[0] == s:TokenValue.NAME &&
              \ self.stashed[1] ==# 'async'
          let self.async_def = 1
          let self.async_def_indent = self.cur_indent
          let self.stashed[0] = s:TokenValue.ASYNC
        endif
        return s:TokenInfo(s:TokenValue.NAME, token, spos, epos, self.line)
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
        return s:TokenInfo(type, token, spos, epos, self.line)
      endif
    endwhile
  endwhile
endfunction

function! s:Tokenizer.GetNextToken() abort
  if self.error_or_end
    if self.stashed isnot 0
      let [tok, self.stashed] = [self.stashed, 0]
      return tok
    endif
    throw 'StopIteration'
  endif
  let tok = self._tokenize()
  let [tok, self.stashed] = [self.stashed, tok]
  return tok
endfunction

" Handle errors during tokenization.
function! s:Tokenizer._on_error(type, msg) abort
  let self.error_or_end = 1
  let self.stashed = 0
  let msg = printf('%s: %s:%d:%d: %s',
        \ a:type, self.filename, self.lnum, self.cpos, a:msg)
  throw msg
endfunction

" Create a Tokenizer from path.
function! tokenize#FromFile(path)
  let tknr = deepcopy(s:Tokenizer)
  let tknr.buffer_ = readfile(a:path)
  let tknr.buffer_size = len(tknr.buffer_)
  let tknr.filename = a:path
  let encoding = tokenize#codecs#detect_encoding(tknr.buffer_, tknr.buffer_size, tknr.filename)
  let tknr._encoding = g:tokenize#lookup#Table[encoding]
  let tknr.stashed = s:TokenInfo(s:TokenValue.ENCODING, encoding, [0, 0], [0, 0], '')
  return tknr
endfunction

" Escapes table from scriptease.vim
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

" Turn a string into repr(string).
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

" Turn token tuple into a dictionary.
function! tokenize#tuple_as_dict(tuple) abort
  return {
        \ 'type': a:tuple[0],
        \ 'string': a:tuple[1],
        \ 'start': a:tuple[2],
        \ 'end': a:tuple[3],
        \ 'line': a:tuple[4]
        \ }
endfunction

" Turn token tuple into a string.
function! tokenize#tuple_as_string(tuple) abort
  let token_range = call('printf', ['%d,%d-%d,%d:']+a:tuple[2]+a:tuple[3])
  return printf('%-20s%-15s%-15S', token_range,
        \ s:TokenName[a:tuple[0]], tokenize#dump(a:tuple[1]))
endfunction

" Tokenize a file with results in a list. Exceptions other than StopIteration
" are throw through.
function! tokenize#list(path, exact) abort
  let tknr = tokenize#FromFile(a:path)
  let tknr.exact = a:exact
  let lst = []
  while 1
    try
      call add(lst, tknr.GetNextToken())
    catch 'StopIteration'
      return lst
    endtry
  endwhile
endfunction

" Tokenize a file, turn the tokens into strings and either writefile() or
" echo.
function! tokenize#main(path, out, exact) abort
  try
    let val = map(tokenize#list(a:path, a:exact), 'tokenize#tuple_as_string(v:val)')
    if a:out ==# '<stdout>'
      echo join(val, "\n")
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
