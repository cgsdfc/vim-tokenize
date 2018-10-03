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
" let s:blank=s:regex("^[ \t\f]*\\%([#\r\n]\\|$\\)")
" let s:Blank=s:regex('^\s*$')

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

" stashed: right after storing a tok into stashed, function must return!
let s:Tokenizer = {
      \ 'line': '',
      \ 'async_def': 0,
      \ 'async_def_indent': 0,
      \ 'async_def_nl': 0,
      \ 'contstr': 0,
      \ 'needcont': 0,
      \ 'continued': 0,
      \ 'stashed': 0,
      \ 'pos': 0,
      \ 'max': 0,
      \ 'cur_indent': 0,
      \ 'error_or_end': 0,
      \ 'bol': 1,
      \ 'buffer_': 0,
      \ 'buffer_size': 0,
      \ 'lnum': 0,
      \ 'parenlev': 0,
      \ 'indents': [0],
      \ }

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
function! s:Tokenizer._tokenize()
  if self.stashed isnot 0
    let tok=self.stashed
    let self.stashed = 0
    return tok
  endif

  while 1
    " detect indent/dedent
    if self.cur_indent < self.indents[-1]
      call self.logger.debug_('pop DEDENT')
      if index(self.indents, self.cur_indent) < 0
        throw s:IndentationError(
              \ "unindent does not match any outer indentation level",
              \ ["<tokenize>", self.lnum, self.pos, self.line])
      endif
      let self.cur_indent = remove(self.indents, -1)
      return s:TokenInfo(s:TokenValue.DEDENT, '', [self.lnum, self.pos],
            \ [self.lnum, self.pos], self.line)
    endif

    if self.lnum == self.buffer_size && self.pos == self.max
      if self.contstr
        throw s:TokenError("EOF in multi-line string", strstart)
      endif
      if self.continued
        throw s:TokenError("EOF in mult-line statement", [self.lnum, 0])
      endif
      if len(self.indents) == 1
        let self.error_or_end=1
        return s:TokenInfo(s:TokenValue.ENDMARKER, '', [self.lnum, 0], [self.lnum, 0], '')
      else
        unlet self.indents[-1]
        return s:TokenInfo(s:TokenValue.DEDENT, '',  [self.lnum, 0], [self.lnum, 0], '')
      endif
    endif

    if self.contstr || self.pos == self.max
      call self.logger.debug_('Fetch line')
      let self.line=self.buffer_[self.lnum]
      let self.lnum += 1
      let [self.pos, self.max]=[0, len(self.line)]

      if self.contstr
        let endmatch = matchlist(self.line, endprog)
        if !empty(endmatch)
          let self.pos = len(endmatch[0])
          let end_ = self.pos
          call add(contstr, self.line[:end_-1])
          call add(contline, self.line)
          let self.contstr = 0
          let self.needcont = 0
          return s:TokenInfo(s:TokenValue.STRING, join(contstr, ''),
                \ strstart, [self.lnum, end_], join(contline, ''))
        elseif self.needcont && self.line[self.max-2:] != "\\\n"
          let self.contstr = 0
          call add(contstr, self.line)
          return s:TokenInfo(s:TokenValue.ERRORTOKEN, join(contstr, ''),
                \ strstart, [self.lnum, len(self.line)], join(contline, ''))
        else
          call add(contstr, self.line)
          call add(contline, self.line)
          continue
        endif
      elseif self.parenlev == 0 && !self.continued " new statement
        call self.logger.debug_('new statement')
        let column = 0
        while self.pos < self.max
          if self.line[self.pos] == ' '
            let column += 1
          elseif self.line[self.pos] == "\t"
            let column = (column / s:TAB_SIZE + 1) * s:TAB_SIZE
          elseif self.line[self.pos] == "\f"
            let column=0
          else
            break
          endif
          let self.pos += 1
        endwhile

        " skip comments or blank lines
        if self.line[self.pos] =~ "[#\n]"
          let start_ = self.pos
          let self.pos = self.max " end this line, do not scan token
          if self.line[start_] == '#'
            let commnet_token = maktaba#string#StripTrailing(self.line[start_:])
            let self.stashed = s:TokenInfo(s:TokenValue.NL, "\n",
                  \ [self.lnum, self.max],
                  \ [self.lnum, self.max+1], self.line)
            return s:TokenInfo(s:TokenValue.COMMENT,
                  \ commnet_token,
                  \ [self.lnum, start_],
                  \ [self.lnum, start_+len(commnet_token)],
                  \ self.line)
          else
            return s:TokenInfo(s:TokenValue.NL, "\n",
                  \ [self.lnum, start_],
                  \ [self.lnum, start_+1],
                  \ self.line)
          endif
        endif

        if column > self.indents[-1]
          call self.logger.debug_('push INDENT')
          call add(self.indents, column)
          return s:TokenInfo(s:TokenValue.INDENT, self.line[:self.pos-1],
                \ [self.lnum, 0], [self.lnum, self.pos], self.line)
        elseif column < self.indents[-1]
          let self.cur_indent = column
          continue " jump to the code that handle dedent
        endif
      else          " continued statement
        let self.continued = 0
      endif
    endif

    call self.logger.debug_('scan for tokens')

    while self.pos < self.max
      let psmat = matchlist(self.line, s:PseudoToken, self.pos)
      if empty(psmat)
        call self.logger.debug_('Bad token')
        let tok = s:TokenInfo(s:TokenValue.ERRORTOKEN, self.line[self.pos],
              \ [self.lnum, self.pos], [self.lnum, self.pos+1], self.line)
        let self.pos += 1
        return tok
      endif

      let entire = psmat[0]
      let token = psmat[1]
      let self.pos += len(entire)
      if empty(token)
        continue
      endif
      let start_ = self.pos-len(token)
      let end_ = self.pos
      let [spos, epos]=[[self.lnum, start_], [self.lnum, end_]]
      let initial = token[0]

      if initial =~ '[0-9]' ||
            \ (initial == '.' && token != '.' && token != '...')
        return s:TokenInfo(s:TokenValue.NUMBER, token, spos, epos, self.line)
      elseif initial == "\n"
        if self.parenlev > 0
          return s:TokenInfo(s:TokenValue.NL, token, spos, epos, self.line)
        else
          return s:TokenInfo(s:TokenValue.NEWLINE, token, spos, epos, self.line)
        endif
      elseif initial == '#'
        return s:TokenInfo(s:TokenValue.COMMENT, token, spos, epos, self.line)
      elseif has_key(s:triple_quoted, token)         " check for triple_quoted
        let endprog = s:endpats[token]
        let endmatch = matchlist(self.line, endprog, self.pos)
        if !empty(endmatch)
          " all in one line
          let self.pos += len(endmatch[0])
          return s:TokenInfo(s:TokenValue.STRING, token, spos, [self.lnum, self.pos], self.line)
        else " multiple lines
          let strstart = [self.lnum, start_]
          let contstr = [self.line[start_:]]
          let contline = [self.line]
          let self.contstr = 1
          break
        endif
      elseif (has_key(s:single_quoted, initial) ||
            \ has_key(s:single_quoted, token[:1]) ||
            \ has_key(s:single_quoted, token[:2]))
        call self.logger.debug_('single_quoted prefix')
        if self.line[end_ - 1] == '\'
          let strstart = [self.lnum, start_]
          let endprog = get(s:endpats, initial,
                \ get(s:endpats, token[1],
                \ get(s:endpats, token[2])))
          let self.needcont = 1
          let self.contstr = 1
          let contstr = [self.line[start_:]]
          let contline = [self.line]
          break
        else
          return s:TokenInfo(s:TokenValue.STRING, token, spos, [self.lnum, self.pos], self.line)
        endif
      elseif initial =~ '[a-zA-Z_]'
        return s:TokenInfo(s:TokenValue.NAME, token, spos, epos, self.line)
      elseif initial == '\'
        let self.continued = 1
      else
        if initial =~ '[([{]'
          let self.parenlev += 1
        elseif initial =~ '[)]}'
          let self.parenlev -= 1
        endif
        return s:TokenInfo(s:TokenValue.OP, token, spos, epos, self.line)
      endif
    endwhile
  endwhile
endfunction
" }}}1

let s:LineScanner = {
      \ 'line': 0,
      \ 'pos': 0,
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

function! s:Tokenizer.GetNextToken() abort
  if self.error_or_end
    throw 'StopIteration'
  endif
  try
    let val=self._tokenize()
    return val
  catch /^Vim(.*):E\d\+:/
    call self.logger.error(v:exception)
    echoerr 'VimError'
  catch /^\w\+/
    let self.error_or_end=1
    throw v:exception
  endtry
endfunction

function! tokenize#FromFile(path)
  let t_=deepcopy(s:Tokenizer)
  let b=readfile(a:path)
  let t_.buffer_=map(b, 'v:val."\n"')
  let t_.buffer_size=len(b)
  let t_.logger = tokenize#logging#get_logger('./test/tokenize.log')
  let t_.logger.filename = s:__file__
  " let t_.logger.log_to_stderr = 1
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
      \}

function! tokenize#dump(str)
  return "'". substitute(a:str, "[\001-\037\\\\']",
        \  '\=get(s:escapes, submatch(0))', 'g')."'"
endfunction

function! tokenize#main(path, out, exact)
  let tknr = tokenize#FromFile(a:path)
  let val = []
  try
    while 1
      let tk = tknr.GetNextToken()
      let token_range = call('printf', ['%d,%d-%d,%d:']+tk[2]+tk[3])
      if tk[0] == s:TokenValue.OP && a:exact
        let tk[0] = s:ExactType[tk[1]]
      endif
      call add(val, printf('%-20s%-15s%-15s', token_range,
            \ s:TokenName[tk[0]], tokenize#dump(tk[1])))
    endwhile
  catch 'StopIteration'
  catch
    call tknr.logger.error(v:exception)
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
