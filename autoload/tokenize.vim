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

let s:cookie="^[ \t\f]*#.\\{-}coding[:=][ \t]*\\([[:alnum:]-.]\\)\\+"
let s:blank="^[ \t\f]*\\%([#\r\n]\\|$\\)"

let s:Whitespace = "[ \f\t]"
let s:Comment = "#[^\r\n]*"
let s:Ignore=s:Whitespace.s:any("\\\r\\=\n".s:Whitespace).s:maybe(s:Comment)
let s:Name = '\w\+'

let s:Hexnumber = '0[xX]\%(_\=[0-9a-fA-F]\)\+'
let s:Binnumber = '0[bB]\%(_\=[01]\)\+'
let s:Octnumber = '0[oO]\%(_\=[0-7]\)\+'
let s:Decnumber = '\%(0\%(_\=0\)*\|[1-9]\%(_\=[0-9]\)*\)'
let s:Intnumber = s:group(s:Hexnumber,s:Binnumber,s:Octnumber,s:Decnumber)

let s:Exponent = '[eE][-+]\=[0-9]\%(_\=[0-9]\)*'
let s:Pointfloat = s:group('[0-9]\%(_\=[0-9]\)*\.\%([0-9]\%(_\=[0-9]\)*\)\=',
      \ '\.[0-9]\%(_\=[0-9]\)*').s:maybe(s:Exponent)
let s:Expfloat = '[0-9]\%(_\=[0-9]\)*'.s:Exponent
let s:Floatnumber = s:group(s:Pointfloat, s:Expfloat)
let s:Imagnumber = s:group('[0-9]\%(_\=[0-9]\)*[jJ]',s:Floatnumber.'[jJ]')
let s:Number = s:group(s:Imagnumber,s:Floatnumber,s:Intnumber)

let s:Single='[^''\\]*\%(\\.[^''\\]*\)*'''
let s:Double='[^"\\]*\%(\\.[^"\\]*\)*"'
let s:Single3='[^''\\]*\%(\%(\\.\|''\%(''''\)\@!\)[^''\\]*\)*'''''''
let s:Double3='[^"\\]*\%(\%(\\.\|"\%(""\)\@!\)[^"\\]*\)*"""'
let s:StringPrefix = '\('.join(s:all_string_prefixes, '\|').'\)'
let s:Triple=s:group(s:StringPrefix."'''",s:StringPrefix.'"""')

let s:String=s:group(s:StringPrefix.
      \ '''[^'."\n".'''\\]*\%(\\.[^'."\n".'''\\]*\)*''',
      \ s:StringPrefix.'"[^'."\n".'"\\]*\%(\\.[^'."\n".'"\\]*\)*"')

let s:Operator=s:group('\*\*=\=', '>>=\=', '<<=\=', '!=',
            \ '//=', '->',
            \ '[+\-*/%&@|^=<>]=\=',
            \ '\~')

let s:Bracket='[][(){}]'
let s:Special=s:group("\r\\=\n", '\.\.\.', '[:;.,@]')
let s:Funny=s:group(s:Operator,s:Bracket,s:Special)

let s:PlainToken=s:group(s:Number,s:Funny,s:String,s:Name)
let Token=s:Ignore.s:PlainToken

let s:ContStr=s:group(s:StringPrefix."[^\n'\\]*\\%(\\.[^\n'\\]*\\)*"
            \ .s:group("'", "\\\r\\=\n"),
            \ s:StringPrefix."\"[^\n\"\\]*\\%(\\.[^\n\"\\]*\\)*"
            \ .s:group('"', "\\\r\\=\n"))
let s:PseudoExtras=s:group("\\\r\\=\n\\|\\%$", s:Comment, s:Triple)
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

function! s:TokenInfo(type, string, start, end, line)
  return {
        \ 'type': a:type,
        \ 'string': a:string,
        \ 'start': a:start,
        \ 'line': a:line,
        \ }
endfunction

function! tokenize#scriptdict()
  return s:
endfunction
