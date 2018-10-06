import re
from collections import defaultdict

PLACE_HOLDER=re.compile(r'{{ (?P<name>[a-zA-Z_][_a-zA-Z0-9]*) }}')

class Template:
    def __repr__(self):
        return '<Template({})>'.format(self.names)

    def __init__(self, template):
        self.names=set(PLACE_HOLDER.findall(template))
        template=PLACE_HOLDER.sub(r'{\1}', template)
        self.template=template

    def substitute(self, **kwds):
        for name in self.names:
            if name not in kwds:
                kwds[name]=''
        return self.template.format(**kwds)

def main():
    m,n=map(int, input().split())
    template='\n'.join(input() for i in range(m))
    lines=[input().split(sep=' ',maxsplit=1) for i in range(n)]
    names={name: eval(val) for name,val in lines}
    template=Template(template)
    print(template.substitute(**names))

if __name__=='__main__':
    main()
