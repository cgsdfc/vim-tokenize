" Generated by gentokens.py (Version 0.0.5). Do not edit.

let tokenize#token#Value={}
let tokenize#token#Value.ENDMARKER=0
let tokenize#token#Value.NAME=1
let tokenize#token#Value.NUMBER=2
let tokenize#token#Value.STRING=3
let tokenize#token#Value.NEWLINE=4
let tokenize#token#Value.INDENT=5
let tokenize#token#Value.DEDENT=6
let tokenize#token#Value.LPAR=7
let tokenize#token#Value.RPAR=8
let tokenize#token#Value.LSQB=9
let tokenize#token#Value.RSQB=10
let tokenize#token#Value.COLON=11
let tokenize#token#Value.COMMA=12
let tokenize#token#Value.SEMI=13
let tokenize#token#Value.PLUS=14
let tokenize#token#Value.MINUS=15
let tokenize#token#Value.STAR=16
let tokenize#token#Value.SLASH=17
let tokenize#token#Value.VBAR=18
let tokenize#token#Value.AMPER=19
let tokenize#token#Value.LESS=20
let tokenize#token#Value.GREATER=21
let tokenize#token#Value.EQUAL=22
let tokenize#token#Value.DOT=23
let tokenize#token#Value.PERCENT=24
let tokenize#token#Value.LBRACE=25
let tokenize#token#Value.RBRACE=26
let tokenize#token#Value.EQEQUAL=27
let tokenize#token#Value.NOTEQUAL=28
let tokenize#token#Value.LESSEQUAL=29
let tokenize#token#Value.GREATEREQUAL=30
let tokenize#token#Value.TILDE=31
let tokenize#token#Value.CIRCUMFLEX=32
let tokenize#token#Value.LEFTSHIFT=33
let tokenize#token#Value.RIGHTSHIFT=34
let tokenize#token#Value.DOUBLESTAR=35
let tokenize#token#Value.PLUSEQUAL=36
let tokenize#token#Value.MINEQUAL=37
let tokenize#token#Value.STAREQUAL=38
let tokenize#token#Value.SLASHEQUAL=39
let tokenize#token#Value.PERCENTEQUAL=40
let tokenize#token#Value.AMPEREQUAL=41
let tokenize#token#Value.VBAREQUAL=42
let tokenize#token#Value.CIRCUMFLEXEQUAL=43
let tokenize#token#Value.LEFTSHIFTEQUAL=44
let tokenize#token#Value.RIGHTSHIFTEQUAL=45
let tokenize#token#Value.DOUBLESTAREQUAL=46
let tokenize#token#Value.DOUBLESLASH=47
let tokenize#token#Value.DOUBLESLASHEQUAL=48
let tokenize#token#Value.AT=49
let tokenize#token#Value.ATEQUAL=50
let tokenize#token#Value.RARROW=51
let tokenize#token#Value.ELLIPSIS=52
let tokenize#token#Value.OP=53
let tokenize#token#Value.AWAIT=54
let tokenize#token#Value.ASYNC=55
let tokenize#token#Value.ERRORTOKEN=56
let tokenize#token#Value.N_TOKENS=60
let tokenize#token#Value.NT_OFFSET=256
let tokenize#token#Value.COMMENT=57
let tokenize#token#Value.NL=58
let tokenize#token#Value.ENCODING=59

let tokenize#token#Name={}
let tokenize#token#Name[0]='ENDMARKER'
let tokenize#token#Name[1]='NAME'
let tokenize#token#Name[2]='NUMBER'
let tokenize#token#Name[3]='STRING'
let tokenize#token#Name[4]='NEWLINE'
let tokenize#token#Name[5]='INDENT'
let tokenize#token#Name[6]='DEDENT'
let tokenize#token#Name[7]='LPAR'
let tokenize#token#Name[8]='RPAR'
let tokenize#token#Name[9]='LSQB'
let tokenize#token#Name[10]='RSQB'
let tokenize#token#Name[11]='COLON'
let tokenize#token#Name[12]='COMMA'
let tokenize#token#Name[13]='SEMI'
let tokenize#token#Name[14]='PLUS'
let tokenize#token#Name[15]='MINUS'
let tokenize#token#Name[16]='STAR'
let tokenize#token#Name[17]='SLASH'
let tokenize#token#Name[18]='VBAR'
let tokenize#token#Name[19]='AMPER'
let tokenize#token#Name[20]='LESS'
let tokenize#token#Name[21]='GREATER'
let tokenize#token#Name[22]='EQUAL'
let tokenize#token#Name[23]='DOT'
let tokenize#token#Name[24]='PERCENT'
let tokenize#token#Name[25]='LBRACE'
let tokenize#token#Name[26]='RBRACE'
let tokenize#token#Name[27]='EQEQUAL'
let tokenize#token#Name[28]='NOTEQUAL'
let tokenize#token#Name[29]='LESSEQUAL'
let tokenize#token#Name[30]='GREATEREQUAL'
let tokenize#token#Name[31]='TILDE'
let tokenize#token#Name[32]='CIRCUMFLEX'
let tokenize#token#Name[33]='LEFTSHIFT'
let tokenize#token#Name[34]='RIGHTSHIFT'
let tokenize#token#Name[35]='DOUBLESTAR'
let tokenize#token#Name[36]='PLUSEQUAL'
let tokenize#token#Name[37]='MINEQUAL'
let tokenize#token#Name[38]='STAREQUAL'
let tokenize#token#Name[39]='SLASHEQUAL'
let tokenize#token#Name[40]='PERCENTEQUAL'
let tokenize#token#Name[41]='AMPEREQUAL'
let tokenize#token#Name[42]='VBAREQUAL'
let tokenize#token#Name[43]='CIRCUMFLEXEQUAL'
let tokenize#token#Name[44]='LEFTSHIFTEQUAL'
let tokenize#token#Name[45]='RIGHTSHIFTEQUAL'
let tokenize#token#Name[46]='DOUBLESTAREQUAL'
let tokenize#token#Name[47]='DOUBLESLASH'
let tokenize#token#Name[48]='DOUBLESLASHEQUAL'
let tokenize#token#Name[49]='AT'
let tokenize#token#Name[50]='ATEQUAL'
let tokenize#token#Name[51]='RARROW'
let tokenize#token#Name[52]='ELLIPSIS'
let tokenize#token#Name[53]='OP'
let tokenize#token#Name[54]='AWAIT'
let tokenize#token#Name[55]='ASYNC'
let tokenize#token#Name[56]='ERRORTOKEN'
let tokenize#token#Name[60]='N_TOKENS'
let tokenize#token#Name[256]='NT_OFFSET'
let tokenize#token#Name[57]='COMMENT'
let tokenize#token#Name[58]='NL'
let tokenize#token#Name[59]='ENCODING'

let tokenize#token#ExactType={}
let tokenize#token#ExactType['(']=7
let tokenize#token#ExactType[')']=8
let tokenize#token#ExactType['[']=9
let tokenize#token#ExactType[']']=10
let tokenize#token#ExactType[':']=11
let tokenize#token#ExactType[',']=12
let tokenize#token#ExactType[';']=13
let tokenize#token#ExactType['+']=14
let tokenize#token#ExactType['-']=15
let tokenize#token#ExactType['*']=16
let tokenize#token#ExactType['/']=17
let tokenize#token#ExactType['|']=18
let tokenize#token#ExactType['&']=19
let tokenize#token#ExactType['<']=20
let tokenize#token#ExactType['>']=21
let tokenize#token#ExactType['=']=22
let tokenize#token#ExactType['.']=23
let tokenize#token#ExactType['%']=24
let tokenize#token#ExactType['{']=25
let tokenize#token#ExactType['}']=26
let tokenize#token#ExactType['==']=27
let tokenize#token#ExactType['!=']=28
let tokenize#token#ExactType['<=']=29
let tokenize#token#ExactType['>=']=30
let tokenize#token#ExactType['~']=31
let tokenize#token#ExactType['^']=32
let tokenize#token#ExactType['<<']=33
let tokenize#token#ExactType['>>']=34
let tokenize#token#ExactType['**']=35
let tokenize#token#ExactType['+=']=36
let tokenize#token#ExactType['-=']=37
let tokenize#token#ExactType['*=']=38
let tokenize#token#ExactType['/=']=39
let tokenize#token#ExactType['%=']=40
let tokenize#token#ExactType['&=']=41
let tokenize#token#ExactType['|=']=42
let tokenize#token#ExactType['^=']=43
let tokenize#token#ExactType['<<=']=44
let tokenize#token#ExactType['>>=']=45
let tokenize#token#ExactType['**=']=46
let tokenize#token#ExactType['//']=47
let tokenize#token#ExactType['//=']=48
let tokenize#token#ExactType['@']=49
let tokenize#token#ExactType['@=']=50

let tokenize#token#AllStringPrefixes=['', 'Rf', 'b', 'br', 'F', 'fr', 'rf', 'R', 'Fr', 'FR', 'f', 'B', 'BR', 'U', 'rB', 'r', 'RF', 'u', 'Rb', 'fR', 'Br', 'bR', 'RB', 'rF', 'rb']