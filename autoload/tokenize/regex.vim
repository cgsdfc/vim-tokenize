" This file aims to clear regex stuffs out of tokenize.vim

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

let s:Cookie = s:regex("^[ \t\f]*#.\\{-}coding[:=][ \t]*\\([[:alnum:]-.]\\+\\)")
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

let s:StringPrefix = s:regex(s:lgroup(g:tokenize#token#AllStringPrefixes))
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

" Expose all regex strings.
function! tokenize#regex#all()
  return s:
endfunction
