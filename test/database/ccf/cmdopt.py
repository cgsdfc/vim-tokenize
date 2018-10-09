import re
from operator import itemgetter

VALID_ARG=re.compile(r'[a-z0-9-]+')

def parse_input():
    option_desc=input()
    N=int(input())
    lines=[input() for i in range(N)]
    return (option_desc,N,lines)

def parse_option_desc(desc_str):
    '''Parse the option description string.
    Return a dict where d[c]=True if c accepts an argument
    else False.
    '''
    res={}
    for i,c in enumerate(desc_str):
        if c==':':
            res[desc_str[i-1]]=True
        else:
            res[c]=False
    return res

class CmdlineParser:
    '''Parse a cmdline given a description of the option format.'''

    def __init__(self, desc_str):
        self.desc=parse_option_desc(desc_str)

    def iter_argv(self, argv):
        '''``argv`` is a list of items, yield options from it.
        If it takes an arg, (opt, arg) is yield.
        If it takes none, (opt, '') is yield.
        ``opt`` does not have a leading '-'.
        '''
        i=0
        while i<len(argv):
            if argv[i].startswith('-'):
                opt=argv[i][1:]
                if opt not in self.desc:
                    # Not a valid option
                    break
                if self.desc[opt]:
                    # option takes an argument
                    try:
                        arg=argv[i+1]
                    except IndexError:
                        # Not enough arg
                        break
                    if VALID_ARG.match(arg):
                        yield (opt, arg)
                        i+=1
                    else:
                        # Not a valid arg
                        break
                else:
                    yield (opt,'')
            else:
                # Take-no-arg option saw an arg
                break
            i+=1

    def _dump(self, options):
        '''Dump ``options`` into a string.
        Options are sorted by their chars.
        '''
        return ' '.join('-{} {}'.format(*args) if args[1] else
                '-' + args[0] for args in sorted(options,key=itemgetter(0)))

    def parse(self, line):
        '''Parse ``line`` into a string, where each option (and its
        arg) is separated by a single space.
        If an option appears multiple times, only one will be shown.
        If it takes an arg, only the last arg will be shown.
        '''
        line=line.split(' ')
        argv=line[1:]
        options=dict(self.iter_argv(argv))
        return self._dump(options.items())


def main():
    desc,N,lines=parse_input()
    parser=CmdlineParser(desc)
    for i,line in enumerate(lines, 1):
        print('Case {}: {}'.format(i, parser.parse(line)))


if __name__=='__main__':
    main()
