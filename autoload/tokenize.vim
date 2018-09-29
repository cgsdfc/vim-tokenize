let s:token=g:tokenize#token#token

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

let s:all_string_prefixes=[
      \ '' , "r" , "u" , "R" , "U" , "f" , "F",
      \ "fr" , "Fr" , "fR" , "FR" , "rf" , "rF" , "Rf" , "RF",
      \ "b" , "B" , "br" , "Br" , "bR" , "BR" , "rb" , "rB" , "Rb" , "RB"
      \]

let s:cookie=s:regex("^[ \t\f]*#.\\{-}coding[:=][ \t]*\\([[:alnum:]-.]\\)\\+")
let s:blank=s:regex("^[ \t\f]*\\%([#\r\n]\\|$\\)")

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
let s:StringPrefix = s:regex('\('.join(s:all_string_prefixes, '\|').'\)')
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
for s:prefix in s:all_string_prefixes
    let s:endpats[s:prefix."'"]=s:Single
    let s:endpats[s:prefix.'"']=s:Double
    let s:endpats[s:prefix."'''"]=s:Single3
    let s:endpats[s:prefix.'"""']=s:Double3
endfor

let s:Tokenizer = {
      \ 'readline': v:none,
      \ 'lnum': 0,
      \ 'parenlev': 0,
      \ 'contstr': '',
      \ 'needcont': v:false,
      \ 'indents': [0],
      \ 'async_def': v:false,
      \ 'async_def_indent': 0,
      \ 'async_def_nl': v:false,
      \ }

function! tokenize#scriptdict()
  return s:
endfunction

function! tokenize#detect_encoding(readline) abort
  let line=a:readline()
  let match=matchlist(line, s:cookie)[1]
endfunction

function! tokenize#tokenize() dict
  if self.column > self.indents[-1]
    call add(self.indents, self.column)
    return [s:tokens.INDENT]
  endif
endfunction
