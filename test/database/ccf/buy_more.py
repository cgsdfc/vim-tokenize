PRICE=10

def break_down(nb):
    '''Break a number which is a multiple of PRICE
    in 2 parts (both are multiples of PRICE) that sum back to nb.
    '''
    for i in range(PRICE, nb // 2 + 1, PRICE):
        yield (i, nb-i)

def buy_with(nb):
    '''Return the items we can buy with ``nb``.'''
    if nb % (3*PRICE) == 0:
        return nb // PRICE + 1
    if nb % (5*PRICE) == 0:
        return nb // PRICE + 2
    return nb // PRICE

class Main:
    def __repr__(self):
        return repr(self.cache)

    def __init__(self, N):
        assert N >= PRICE
        self.N=N
        self.cache={}

    def find_max(self):
        '''Find the maximum number of items we can buy'''
        self.cache[PRICE]=1

        for i in range(PRICE*2, self.N+1, PRICE):
            self.cache[i]=max(buy_with(i),
                    max(self.cache[x]+self.cache[y]
                    for x,y in break_down(i)))
        return self.cache[self.N]

if __name__=='__main__':
    N=int(input())
    if N==0:
        print(0)
    else:
        m=Main(N)
        print(m.find_max())
