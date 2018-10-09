let s:TAB_SIZE=8
let s:TokenValue=tokenize#token#Value
let s:TokenName=tokenize#token#Name
let s:AllStringPrefixes=tokenize#token#AllStringPrefixes
let s:ExactType=tokenize#token#ExactType
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

" function! s:any(...) abort
"   return call('s:group', a:000).'*'
" endfunction

function! s:maybe(...) abort
  return call('s:group', a:000).'\='
endfunction

function! s:TokenInfo(type, string, start_, end_, line)
  return [a:type, a:string, a:start_, a:end_, a:line]
endfunction

let s:cookie=s:regex("^[ \t\f]*#.\\{-}coding[:=][ \t]*\\([[:alnum:]-.]\\)\\+")
let s:Blank=s:regex("^[ \t\f]*\\%([#\r\n]\\|$\\)")

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

let s:Single=s:regex('[^''\\]*\%(\\.[^''\\]*\)*''')
let s:Double=s:regex('[^"\\]*\%(\\.[^"\\]*\)*"')
let s:Single3=s:regex('[^''\\]*\%(\%(\\.\|''\%(''''\)\@!\)[^''\\]*\)*''''''')
let s:Double3=s:regex('[^"\\]*\%(\%(\\.\|"\%(""\)\@!\)[^"\\]*\)*"""')
let s:StringPrefix = s:regex(s:lgroup(s:AllStringPrefixes))
let s:Triple=s:group(s:StringPrefix."'''", s:StringPrefix.'"""')

" let s:String=s:group(s:StringPrefix.
"       \ '''[^'."\n".'''\\]*\%(\\.[^'."\n".'''\\]*\)*''',
"       \ s:StringPrefix.'"[^'."\n".'"\\]*\%(\\.[^'."\n".'"\\]*\)*"')

let s:Operator=s:regex(s:group('\*\*=\=', '>>=\=', '<<=\=', '!=',
            \ '//=\?', '->',
            \ '[+\-*/%&@|^=<>]=\=',
            \ '\~'))

let s:Bracket=s:regex('[][(){}]')
let s:Special=s:regex(s:group("\n", '\.\.\.', '[:;.,@]'))
let s:Funny=s:group(s:Operator,s:Bracket,s:Special)

" First (or only) line of ' or " string.
let s:ContStr=s:group(s:StringPrefix."'[^'\n\\\\]*\\%(\\\\.[^'\n\\\\]*\\)*"
            \ .s:group("'", "\\\\\n"),
            \ s:StringPrefix."\"[^\"\n\\\\]*\\%(\\\\.[^\"\n\\\\]*\\)*"
            \ .s:group('"', "\\\\\n"))
let s:PseudoExtras=s:group("\\\\\n\\|\\%$", s:Comment, s:Triple)
let s:PseudoToken = '^'.s:Whitespace.s:cgroup(
      \ s:PseudoExtras,
      \ s:Number,
      \ s:Funny,
      \ s:ContStr,
      \ s:Name)
let tokenize#PseudoToken=s:PseudoToken

let s:endpats={}
for s:prefix in s:AllStringPrefixes
    let s:endpats[s:prefix."'"]=s:Single
    let s:endpats[s:prefix.'"']=s:Double
    let s:endpats[s:prefix."'''"]=s:Single3
    let s:endpats[s:prefix.'"""']=s:Double3
endfor

let s:single_quoted={}
let s:triple_quoted={}
for s:t in s:AllStringPrefixes
  let s:single_quoted[s:t.'"']=1
  let s:single_quoted[s:t."'"]=1
  let s:triple_quoted[s:t.'"""']=1
  let s:triple_quoted[s:t."'''"]=1
endfor

function! tokenize#scriptdict()
  return s:
endfunction

" function! tokenize#detect_encoding(readline) abort
"   let line=a:readline()
"   let match=matchlist(line, s:cookie)[1]
" endfunction

function! s:IndentationError(msg, args)
  return a:msg
endfunction

function! s:TokenError(msg, args)
  return a:msg
endfunction

" {{{1
function! tokenize#GetNextToken() dict abort
  if self.error_or_end
    throw 'StopIteration'
  endif

  while 1
    " detect indent/dedent
    if self.cur_indent < self.indents[-1]
      if index(self.indents, self.cur_indent) < 0
        let self.error_or_end = 1
        throw s:IndentationError(
              \ "unindent does not match any outer indentation level",
              \ ["<tokenize>", self.lnum, self.cpos, self.line])
      endif
      unlet self.indents[-1]
      if self.async_def && self.async_def_indent > self.indents[-1]
        let self.async_def = 0
        let self.async_def_nl = 0
        let self.async_def_indent = 0
      endif
      let tok = s:TokenInfo(s:TokenValue.DEDENT, '',
            \ [self.lnum, self.cpos],
            \ [self.lnum, self.cpos], self.line)
      if self.stashed isnot 0
        let [tok, self.stashed] = [self.stashed, tok]
      endif
      return tok
    endif

    if self.async_def && self.async_def_indent > self.indents[-1]
      let self.async_def = 0
      let self.async_def_nl = 0
      let self.async_def_indent = 0
    endif

    if self.lnum >= self.buffer_size && self.pos >= self.max
      if self.contstr
        let self.error_or_end = 1
        throw s:TokenError("EOF in multi-line string", strstart)
      endif
      if self.continued
        let self.error_or_end = 1
        throw s:TokenError("EOF in mult-line statement", [self.lnum, 0])
      endif
      if self.stashed isnot 0
        let [tok, self.stashed] = [self.stashed, 0]
        return tok
      endif
      let last_line = self.buffer_size + 1
      if len(self.indents) == 1
        let self.error_or_end = 1
        return s:TokenInfo(s:TokenValue.ENDMARKER, '', [last_line, 0], [last_line, 0], '')
      else
        unlet self.indents[-1]
        return s:TokenInfo(s:TokenValue.DEDENT, '',  [last_line, 0], [last_line, 0], '')
      endif
    endif

    if self.contstr || self.pos >= self.max
      let self.line=self.buffer_[self.lnum]
      let self.lnum += 1
      let [self.pos, self.max] = [0, len(self.line)]
      let [self.cpos, self.cmax] = [0, strchars(self.line)]

      if self.contstr
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
          if self.stashed isnot 0
            let [tok, self.stashed] = [self.stashed, tok]
          endif
          return tok
        elseif self.needcont && self.line[self.max-2:] != "\\\n"
          let self.contstr = 0
          call add(contstr, self.line)
          let tok = s:TokenInfo(s:TokenValue.ERRORTOKEN,
                \ join(contstr, ''), strstart,
                \ [self.lnum, self.cmax)], join(contline, ''))
          if self.stashed isnot 0
            let [tok, self.stashed] = [self.stashed, tok]
          endif
          return tok
        else
          call add(contstr, self.line)
          call add(contline, self.line)
          continue
        endif
      elseif self.parenlev == 0 && !self.continued " new statement
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
            if self.stashed isnot 0
              let [tok, self.stashed] = [self.stashed, tok]
            endif
            return tok
          elseif column < self.indents[-1]
            continue " jump to the code that handle dedent
          endif
        endif
      else          " continued statement
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
        if self.line[end_ - 1] == '\'
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
        if token ==# 'async' || token ==# 'await'
          if self.async_def
            let tok = s:TokenInfo(token == 'async' ?
                  \ s:TokenValue.ASYNC : s:TokenValue.AWAIT,
                  \ token, spos, epos, self.line)
          endif
        endif
        let tok = s:TokenInfo(s:TokenValue.NAME, token, spos, epos, self.line)
        if token ==# 'async' && self.stashed is 0
          let self.stashed = tok
          continue
        endif
        if token ==# 'def'
          if self.stashed isnot 0 &&
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
        let tok = s:TokenInfo(s:TokenValue.OP, token, spos, epos, self.line)
      endif
      if self.stashed isnot 0
        let [tok, self.stashed] = [self.stashed, tok]
      endif
      return tok
    endwhile
  endwhile
endfunction
" }}}1

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

function! tokenize#ScanLine(line) abort
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

let s:Tokenizer = {
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
      \ 'bol': 1,
      \ 'buffer_': 0,
      \ 'buffer_size': 0,
      \ 'lnum': 0,
      \ 'parenlev': 0,
      \ 'indents': [0],
      \ 'GetNextToken': function('tokenize#GetNextToken'),
      \ }

function! tokenize#FromFile(path)
  let t_=deepcopy(s:Tokenizer)
  let b=readfile(a:path)
  let t_.buffer_=map(b, 'v:val."\n"')
  let t_.buffer_size=len(b)
  let t_.logger = tokenize#logging#get_logger('./test/tokenize.log1')
  " TODO: We can check self.lnum == 0 at the beginning of the
  " tokenize loop to return the encoding token.
  let t_.stashed = s:TokenInfo(s:TokenValue.ENCODING, 'utf-8',
        \ [0, 0], [0, 0], '')
  let t_.logger.filename = s:__file__
  let t_.logger.log_to_stderr = 1
  return t_
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

function! tokenize#main(path, out, exact)
  let tknr = tokenize#FromFile(a:path)
  let val = []
  try
    while 1
      let tk = tknr.GetNextToken()
      let token_range = call('printf', ['%d,%d-%d,%d:']+tk[2]+tk[3])
      let type = tk[0]
      if type == s:TokenValue.OP && a:exact
        let type = get(s:ExactType, tk[1], type)
      endif
      call add(val, printf('%-20s%-15s%-15S', token_range,
            \ s:TokenName[type], tokenize#dump(tk[1])))
    endwhile
  catch 'StopIteration'
  catch
    call tknr.logger.error(v:exception)
    call tknr.logger.error(v:throwpoint)
  finally
    call tknr.logger.flush()
  endtry
  if a:out ==# '<stdout>'
    echo join(val, "\n")
  else
    call writefile(val, a:out)
  endif
endfunction

" vim:set fdm=markers
