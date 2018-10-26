Tokenize
========

Python tokenizer written in Vimscript.
It is compatible with the `tokenize` module in the python standard library.

Commands
========

```vim
  :Tokenize <file>
```
Tokenize one file and `echo` the result in a manner similar to ``python3 -m tokenize <file>``.
```vim
  :TokenizeDiff <file>
```
This is a internal command for testing. It runs ``tokenize()`` in both vim and python version and
puts their result in diff mode.

Functions
=========
```vim
  tokenize#FromFile(path, exact)
```
Create a ``Tokenizer`` to tokenize `path`. `exact` tells the tokenizer to return exact token type for
``OP`` tokens such as ``<<=`` and ``+=`` instead of returning a broad type ``OP``.

```vim
  Tokenizer.GetNextToken()
```
Return the next token if available. This is an iterative function and it throws ``StopIteration`` when
there is no more tokens.
The returned token is a list of 5 items as ``[type, string, start, end, line]``.
The meanings of these fields are as they are in the python version.
```vim
  tokenize#list(file, exact)
```
This is a helper function to create a tokenizer, consume it and concatenate its results in a list.

Limitaions
==========
Currently it requires ``+iconv`` to run. However, the encoding name discovery is not always successful.
As a result, only utf-8 is supported. Files in other encoding may cause it to fail.

Tests
=====
It is tested on the standard library of python3.6 and the demo code of python3.7.

Performance
===========
It is slow in a real sense.
It is about 100x slower than the python counterpart.

LICENSE
=======
Python Software Foundation License.
