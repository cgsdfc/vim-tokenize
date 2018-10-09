from itertools import product

def parse_input():
    N=int(input())
    retangs=[tuple(int(c) for c in input().split()) for i in range(N)]
    return (N,retangs)

class Retangular:
    def __repr__(self):
        return '<Retangular:X{}, Y{}>'.format(self.xpair, self.ypair)

    def __init__(self, coordinates):
        '''``coordinates`` should be (x1,y1,x2,y2)'''
        self.xpair=tuple(coordinates[i] for i in (0,2))
        self.ypair=tuple(coordinates[i] for i in (1,3))

    def ranges(self):
        '''Return (X, Y), where X is the range of x coordinates,
        Y is the range of y coordinates
        '''
        return (range(*self.xpair),range(*self.ypair))

    def iter_cells(self):
        'Iterate all cells covered by this Retangular'
        for c in product(*self.ranges()):
            yield c

class AreaCalculator:
    '''Calulate the union of areas occupied by a list of Retangulars'''
    MAX_N=100 # 最大的横坐标和纵坐标

    def __init__(self):
        self.area=set()

    def hash_point(self, point):
        return point[0]*self.MAX_N+point[1]

    def compute(self, retangs):
        for retang in retangs:
            for c in retang.iter_cells():
                self.area.add(self.hash_point(c))
        return len(self.area)

def main():
    N,retangs=parse_input()
    print(AreaCalculator().compute(map(Retangular, retangs)))

if __name__=='__main__':
    main()
