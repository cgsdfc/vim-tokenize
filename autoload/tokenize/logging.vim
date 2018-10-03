let s:Logger = {
      \ 'dest': '',
      \ 'filename': '',
      \ 'buffer_': [],
      \ 'log_to_stderr': 0,
      \ 'min_level': 0,
      \ }

let tokenize#logging#Level = {}
let tokenize#logging#Level.DEBUG = 0
let tokenize#logging#Level.INFO = 1
let tokenize#logging#Level.WARNING = 2
let tokenize#logging#Level.ERROR = 3

let s:LevelName = {}
for [s:name, s:val] in items(tokenize#logging#Level)
  let s:LevelName[s:val] = s:name
endfor

function! tokenize#logging#get_logger(dest) abort
  let lg_ = deepcopy(s:Logger)
  let lg_.min_level = g:tokenize#logging#Level.DEBUG
  let lg_.dest = a:dest
  if !filewritable(a:dest)
    call writefile([], a:dest)
  endif
  return lg_
endfunction

function! s:Logger._log(level, msg, args)
  let pid = printf('PID(%d)', getpid())
  let time = strftime('%c')
  let path = printf('"%s"', fnamemodify(self.filename, ':p'))
  let level = printf('[%s]', s:LevelName[a:level])
  let content = len(a:args) ? call('printf', [a:msg] + a:args) : a:msg
  let entry = printf('%s %s %s %s: %s', pid, time, path, level, content)
  if a:level >= self.min_level
    call add(self.buffer_, entry)
  endif
  if self.log_to_stderr
    echo entry
  endif
endfunction

function! s:Logger.shutdown() abort
  call writefile(self.buffer_, self.dest)
  unlet self.buffer_
endfunction

function! s:Logger.info(msg, ...)
  return self._log(g:tokenize#logging#Level.INFO, a:msg, a:000)
endfunction

function! s:Logger.debug_(msg, ...)
  return self._log(g:tokenize#logging#Level.DEBUG, a:msg, a:000)
endfunction

function! s:Logger.warning(msg, ...)
  return self._log(g:tokenize#logging#Level.WARNING, a:msg, a:000)
endfunction

function! s:Logger.error(msg, ...)
  return self._log(g:tokenize#logging#Level.ERROR, a:msg, a:000)
endfunction
