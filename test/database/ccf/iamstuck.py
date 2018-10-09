from pprint import pprint as pp

def parse_input(file_):
    'Parse ``file_``, return as (R,C,chars).'
    R,C=map(int, file_.readline().split())
    chars=tuple(list(file_.readline().strip()) for i in range(R))
    return (R,C,chars)

class Graph:
    '''Given a point, Graph can yield its neighbors.
    Given 2 points, Graph can test whether A->B and whether B->A.
    '''

    SHARP='#'
    VBAR='|'
    MINUS='-'
    PLUS='+'
    DOT='.'
    SOURCE='S'
    TARGET='T'
    ALL_DIRS_CHARS=frozenset((SOURCE,TARGET,PLUS))
    NON_CAN_CHARS=frozenset((TARGET,SHARP))
    ALL_DIRS=((1,0),(0,1),(-1,0),(0,-1))

    @classmethod
    def from_file(cls, path):
        with open(path) as f:
            return cls(*parse_input(f))

    def __init__(self, R, C, chars):
        self.VALID_C_RANGE=range(C)
        self.VALID_R_RANGE=range(R)
        self.chars=chars
        from collections import defaultdict
        self.cache=defaultdict(dict)

    def __repr__(self):
        return repr(self.chars)

    def char(self, point):
        'Return the char at ``point``.'
        try:
            return self.chars[point[0]][point[1]]
        except IndexError as e:
            pp(point)

    def candidates(self):
        'Return a list of candidate points.'
        from itertools import product
        return [p for p in product(self.VALID_R_RANGE,
            self.VALID_C_RANGE) if self.char(p) not in self.NON_CAN_CHARS]

    def iter_neighbors(self, source):
        'Yield neighbors of ``source``.'
        source_char=self.char(source)
        if source_char == self.SHARP:
            return
        for dr,dc in self.ALL_DIRS:
            r,c=source[0]+dr,source[1]+dc
            if r not in self.VALID_R_RANGE or c not in self.VALID_C_RANGE:
                continue
            nb=(r,c)
            char=self.char(nb)
            if char == self.SHARP:
                continue
            if source_char == self.DOT and dr==1:
                # we can only go down
                yield nb
            elif source_char == self.VBAR and dc==0:
                # we can go up (-1) and down (+1)
                yield nb
            elif source_char == self.MINUS and dr==0:
                # we can go left (-1) or right (+1)
                yield nb
            elif source_char in self.ALL_DIRS_CHARS:
                # we can go in all directions
                yield nb

    def is_connected(self, source, target):
        '''Test whether ``source`` is connected to ``target``.
        Note source->target does not imply target->source.
        '''
        seen=set()
        def find_recursively(src):
            if target in self.cache[src]:
                # cached result
                return self.cache[src][target]
            if src == target:
                # trivial case
                return self.cache[src].setdefault(target, True)
            for nb in self.iter_neighbors(src):
                # if my nb can do, so do I
                if nb in seen:
                    # don't see nb twice
                    continue
                seen.add(nb)
                if find_recursively(nb):
                    return True
            return self.cache[src].setdefault(target, False)
        return find_recursively(source)

    def find_by_char(self, char):
        'Return the first point that matches ``char``.'
        for i,r in enumerate(self.chars):
            for j,c in enumerate(r):
                if c==char:
                    return (i,j)
        raise ValueError('char %s not in graph' % char)

class Main:
    IAMSTUCK='I\'am stuck!'

    def __repr__(self):
        return '\n'.join([''.join(r) for r in self.graph.chars])

    def __init__(self, file_):
        self.graph=Graph(*parse_input(file_))
        self.SOURCE=self.graph.find_by_char(Graph.SOURCE)
        self.TARGET=self.graph.find_by_char(Graph.TARGET)
        self.candidates=self.graph.candidates()

    def run(self):
        if not self.graph.is_connected(self.SOURCE, self.TARGET):
            return print(self.IAMSTUCK)
        res=[p for p in self.candidates
                if self.graph.is_connected(self.SOURCE, p) and
                not self.graph.is_connected(p, self.TARGET)]
        # print(res)
        print(len(res))

if __name__=='__main__':
    from sys import stdin
    Main(stdin).run()
