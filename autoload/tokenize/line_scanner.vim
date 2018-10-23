let s:TokenValue=tokenize#token#Value
let s:TokenName=tokenize#token#Name
let s:regex = tokenize#regex#all()

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
    let psmat = matchlist(self.line, s:regex.PseudoToken, self.pos)
    if empty(psmat)
      let self.pos += 1
      let self.cpos += 1
      return [s:TokenValue.ERRORTOKEN, self.line[self.pos-1], [self.pos-1, self.pos]]
    endif
    let entire = psmat[0]
    let token = psmat[1]
    let self.pos += len(entire)
    let self.cpos += strchars(entire)
    if empty(token)
      continue
    endif
    if token is "\n"
      return [s:TokenValue.NL, "\n", [self.cpos, self.cpos+1]]
    endif
    let loc_ = [self.cpos-len(token), self.cpos]
    return [s:TokenValue.OP, token, loc_]
  endwhile
endfunction

function! tokenize#line_scanner#ScanLine(line) abort
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
