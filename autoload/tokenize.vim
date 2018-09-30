let s:TAB_SIZE=8
let s:TokenValue=tokenize#token#Value
let s:AllStringPrefixes=tokenize#token#AllStringPrefixes
let s:ExactType=tokenize#token#ExactType

function! s:regex(str) abort
  return '\m\C'.a:str
endfunction

function! s:group(...) abort
  return '\('.join(a:000, '\|').'\)'
endfunction

function! s:any(...) abort
  return call('s:group', a:000).'*'
endfunction

function! s:maybe(...) abort
  return call('s:group', a:000).'\='
endfunction

let s:cookie=s:regex("^[ \t\f]*#.\\{-}coding[:=][ \t]*\\([[:alnum:]-.]\\)\\+")
let s:blank=s:regex("^[ \t\f]*\\%([#\r\n]\\|$\\)")

let s:Blank=s:regex('^\s*$')
let s:Whitespace = s:regex("[ \f\t]")
let s:Comment = s:regex("#[^\r\n]*")
let s:Ignore=s:Whitespace.s:any("\\\r\\=\n".s:Whitespace).s:maybe(s:Comment)
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
let s:StringPrefix = s:regex('\('.join(s:AllStringPrefixes, '\|').'\)')
let s:Triple=s:group(s:StringPrefix."'''",s:StringPrefix.'"""')

let s:String=s:group(s:StringPrefix.
      \ '''[^'."\n".'''\\]*\%(\\.[^'."\n".'''\\]*\)*''',
      \ s:StringPrefix.'"[^'."\n".'"\\]*\%(\\.[^'."\n".'"\\]*\)*"')

let s:Operator=s:regex(s:group('\*\*=\=', '>>=\=', '<<=\=', '!=',
            \ '//=', '->',
            \ '[+\-*/%&@|^=<>]=\=',
            \ '\~'))

let s:Bracket=s:regex('[][(){}]')
let s:Special=s:regex(s:group("\r\\=\n", '\.\.\.', '[:;.,@]'))
let s:Funny=s:group(s:Operator,s:Bracket,s:Special)

let s:PlainToken=s:group(s:Number,s:Funny,s:String,s:Name)
let Token=s:Ignore.s:PlainToken

let s:ContStr=s:group(s:StringPrefix."[^\n'\\]*\\%(\\.[^\n'\\]*\\)*"
            \ .s:group("'", "\\\r\\=\n"),
            \ s:StringPrefix."\"[^\n\"\\]*\\%(\\.[^\n\"\\]*\\)*"
            \ .s:group('"', "\\\r\\=\n"))
let s:PseudoExtras=s:group(s:regex("\\\r\\=\n\\|\\%$"), s:Comment, s:Triple)
let s:PseudoToken=s:Whitespace.s:group(s:PseudoExtras,s:Number,s:Funny,s:ContStr,s:Name)

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

let s:Tokenizer = {
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

function! tokenize#detect_encoding(readline) abort
  let line=a:readline()
  let match=matchlist(line, s:cookie)[1]
endfunction

function! s:IndentationError(msg, args)
  return a:msg
endfunction

function! s:TokenError(msg, args)
  return a:msg
endfunction

function! s:Tokenizer._tokenize()
  if self.stashed isnot 0
    let tok=self.stashed
    let self.stashed = 0
    return tok
  endif
  while 1
    if self.lnum == self.buffer_size
      if self.contstr
        throw s:TokenError("EOF in multi-line string", strstart)
      endif
      if self.indents[-1] == 0
        let self.error_or_end=1
        return [s:TokenValue.ENDMARKER, '', [self.lnum, 0], [self.lnum, 0], '']
      endif
      unlet self.indents[-1]
      return [s:TokenValue.DEDENT, '',  [self.lnum, 0], [self.lnum, 0], '']
    endif

    if self.pos == self.max || self.contstr
      let self.line=self.buffer_[self.lnum]
      let self.lnum += 1
      if self.contstr
        let endmatch = matchlist(self.line, endprog)
        if !empty(endmatch)
          let self.pos = len(endmatch[0])
          let end_ = self.pos
          call add(contstr, self.line[:end_-1])
          call add(contline, self.line)
          let self.contstr = 0
          return [s:TokenValue.STRING, join(contstr, ''),
                \ strstart, [self.lnum, end_], join(contline, '')]
        elseif self.needcont && self.line[-1] != '\'
          let self.contstr = 0
          call add(contstr, self.line)
          return [s:TokenValue.ERRORTOKEN, join(contstr, ''),
                \ strstart, [self.lnum, len(self.line)], join(contline, '')]
        else
          call add(contstr, self.line[:end_-1])
          call add(contline, self.line)
          continue
        endif
      elseif self.parenlev == 0 && !self.continued " new statement
        let [self.pos, self.max]=[0, len(self.line)]
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
      endif
    endif

    " skip comments or blank lines
    if self.pos == self.max || self.line[self.pos] == '#'
      if self.line[self.pos] == '#'
        let commnet_token = maktaba#string#StripTrailing(self.line[self.pos:])
        let nl_pos = self.pos + len(commnet_token)
        " Stash the NL
        let self.stashed = [s:TokenValue.NL, '', [self.lnum, nl_pos],
              \ [self.lnum, self.max], self.line]
        return [s:TokenValue.COMMENT, commnet_token,
              \ [self.lnum, self.pos], [self.lnum, self.pos+len(commnet_token)],
              \ self.line]
      endif
    else
      return [s:TokenValue.NL, '', [self.lnum, self.pos], [self.lnum, self.max],
            \ self.line]
    endif
    let self.cur_indent = column
    " count indents or dedents
    if column > self.indents[-1]
      call add(self.indents, column)
      return [s:TokenValue.INDENT, self.line[:self.pos-1],
            \ [self.lnum, 0], [self.lnum, self.pos], self.line]
    endif
  endif

  if self.cur_indent < self.indents[-1]
    if index(self.indents, self.cur_indent) < 0
      throw s:IndentationError(
            \ "unindent does not match any outer indentation level",
            \ ["<tokenize>", lnum, pos, line])
    endif
    let self.cur_indent = remove(self.indents, -1)
    return [s:TokenValue.DEDENT, '', [self.lnum, self.pos],
          \ [self.lnum, self.pos], self.line]
  endif

  while self.pos < self.max                    " scan for tokens
    let pseudomatch=matchlist(self.line, s:PseudoToken, self.pos)
    if empty(pseudomatch)
      let tok = [TokenValue.ERRORTOKEN, self.line[self.pos],
            \ [self.lnum, self.pos], [self.lnum, self.pos+1], self.line]
      self.pos += 1
      return tok
    endif
    let [entire, token] = pseudomatch[:1]
    let initial = token[0]
    let start_ =  self.pos+len(entire)-len(token)
    let end_ = self.pos+len(entire)
    let self.pos += len(entire)
    let [spos, epos]=[[start_, self.lnum], [end_, self.lnum]]
    if initial =~ '[0-9]' ||
          \ (initial == '.' && token != '.' && token != '...')
      return [s:TokenValue.NUMBER, token, spos, epos, self.line]
    elseif initial is ''
      if self.parenlev > 0
        return [s:TokenValue.NL, token, spos, epos, self.line]
      else
        if self.async_def
          let self.async_def_nl = 1
        endif
        return [s:TokenValue.NEWLINE, token, spos, epos, self.line]
      elseif initial == '#'
        return [s:TokenValue.COMMENT, token, spos, epos, self.line]
        " check for triple_quoted
      elseif has_key(s:triple_quoted, token)
        let endprog = s:endpats[token]
        let endmatch = matchlist(self.line, endprog, self.pos)
        if !empty(endmatch)
          " all in one line
          let self.pos += len(endmatch[0])
          return [s:TokenValue.STRING, token, spos, [lnum, self.pos], self.line]
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
        if token[-1] == '\'
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
          return [s:TokenValue.STRING, token, spos, [lnum, self.pos], self.line]
        endif
      elseif initial =~ '[a-zA-Z_]'
        if token ==# 'async' || token ==# 'await'
          if self.async_def
            return [token ==# 'async' ? s:TokenValue.ASYNC : s:TokenValue.AWAIT,
                  \ token, spos, epos, self.line]
          endif
        endif
        let tok = [s:TokenValue.NAME, token, spos, epos, self.line]
        if token ==# 'async' && self.stashed is 0
          let self.stashed = tok
          continue
        endif
        if token ==# 'def'
          if self.stashed isnot 0 && self.stashed[0] == s:TokenValue.NAME
                \ && self.stashed[1] ==# 'async'
            let self.async_def = 1
            let self.async_def_indent = self.cur_indent
            let stashed = self.stashed
            let stashed[0] = s:TokenValue.ASYNC
            let self.stashed = 0
            return stashed
          endif
        endif
        return tok
      elseif initial == '\'
        let self.continued = 1
      else
        if initial =~ '[([{]'
          let self.parenlev += 1
        elseif initial =~ '[)]}'
          let self.parenlev -= 1
        endif
        return [TokenValue.OP, token, spos, epos, self.line]
      endif
    endwhile
  endwhile
endfunction


function! s:Tokenizer.GetNextToken() abort
  if self.error_or_end
    throw 'StopIteration'
  endif
  try
    let val=self._tokenize()
  catch
    let self.error_or_end=1
    throw v:exception
  endtry
  return val
endfunction

function! tokenize#FromFile(path)
  let t_=deepcopy(s:Tokenizer)
  let t_.buffer_=readfile(a:path)
  let t_.buffer_size=len(t_.buffer_)
  return t_
endfunction

function! s:do_all(tokenizer)
  let val = []
  try
    while 1
      call add(val, a:tokenizer.GetNextToken())
    endwhile
  catch 'StopIteration'
    return val
  endtry
endfunction

function! tokenize#main(path, out)
  let tokenizer = tokenize#FromFile(a:path)
  let val = []
  try
    for tk in s:do_all(tokenizer)
      let token_range = call('printf', ['%d,%d-%d,%d:']+tk[2]+tk[3])
      call add(val, printf('%-20s%-15s%-15s', token_range,
            \ s:Name[tk[0]], string(tk[1])))
    endfor
  catch
    echo v:exception
  endtry
  call writefile(val, a:out)
endfunction
