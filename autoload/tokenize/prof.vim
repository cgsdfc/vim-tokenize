python3 <<EOF
import timeit
import os
import mmap
import vim

def mapcount(filename):
    f = open(filename, "r+")
    buf = mmap.mmap(f.fileno(), 0)
    lines = 0
    readline = buf.readline
    while readline():
        lines += 1
    return lines

def make_file_list(dir):
    return [os.path.join(dirpath, fname) for dirpath, _, fnames in
        os.walk(dir) for fname in fnames if fname.endswith('.py')]

def sort_on_count(file_list):
    return sorted([(mapcount(fname), fname) for fname in file_list])

def time_one_file(fname):
    stmt = 'vim.eval("tokenize#prof#bare_tokenize(%r)")' % fname
    return timeit.timeit(stmt, number=10, globals=globals())

def time_files(file_list):
    return [(lnum, time_one_file(fname)) for lnum, fname in file_list]

def time_files_dir(dir):
    return time_files(sort_on_count(make_file_list(dir)))

def test(dir):
    return sort_on_count(make_file_list(dir))
EOF

" Do a bare tokenization on path. Without any consumption of the
" tokens.
function! tokenize#prof#bare_tokenize(path) abort
  let tknr = tokenize#FromFile(a:path)
  while 1
    try
      call tknr.GetNextToken()
    catch 'StopIteration'
      return
    endtry
  endwhile
endfunction

function! tokenize#prof#time_files_dir(dir) abort
  return py3eval(printf('time_files_dir("%s")', a:dir))
endfunction

function! tokenize#prof#time_save(dir, output) abort
  call writefile(map(tokenize#prof#time_files_dir(a:dir), 'string(v:val)'), a:output)
endfunction
