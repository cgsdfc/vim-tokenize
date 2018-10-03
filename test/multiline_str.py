"Tokenization help for Python programs.\
\
tokenize(readline) is a generator that breaks a stream of bytes into\
Python tokens.  It decodes the bytes according to PEP-0263 for\
determining source file encoding.\
\
It accepts a readline-like method which is called repeatedly to get the\
next line of input (or b'' for EOF).  It generates 5-tuples with these\
members:\
\
    the token type (see token.py)\
    the token (a string)\
    the starting (row, column) indices of the token (a 2-tuple of ints)\
    the ending (row, column) indices of the token (a 2-tuple of ints)\
    the original line (string)\
\
It is designed to match the working of the Python tokenizer exactly, except\
that it produces COMMENT tokens for comments and gives type OP for all\
operators.  Additionally, all token lists start with an ENCODING token\
which tells you which encoding was used to decode the bytes stream.\
"
