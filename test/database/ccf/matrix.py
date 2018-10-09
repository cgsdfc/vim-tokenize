'''
矩阵快速幂
'''
import array
import logging
import math

class BoolVector:
    'Represent a vector with bool elements'

    def is_zeros(self):
        return not any(self.elements)

    def zeros(self):
        'Return all-zeros vector'
        return BoolVector(0 for _ in range(self.dimension))

    def __repr__(self):
        'The required output format'
        return ''.join(map(str,self.elements))

    def __bool__(self):
        return not self.is_zeros()

    def __init__(self, iterable):
        self.elements=array.array('B', iterable)
        self.dimension=len(self.elements)

    def __getitem__(self, index):
        return self.elements[index]

    def __setitem__(self, index, value):
        # effect performance
        # if value not in range(0,2):
        #     raise ValueError('value can only be 0 or 1')
        self.elements[index]=value


class BoolMatrix:
    'N * N Matrix with bool elements'

    def is_zeros(self):
        'Is it all zerod?'
        return not any(self.elements)

    def is_elementary(self):
        'Is is an identity matrix?'
        for i in self._range:
            for j in self._range:
                if i == j and not self[i,i]:
                    return False
                if i != j and self[i, j]:
                    return False
        return True

    @classmethod
    def from_rows(cls, N, rows):
        'Create from rows ((...),...,(...))'
        out=cls(N)
        for i in out._range:
            for j in out._range:
                out[i,j]=rows[i][j]
        return out

    def elementary(self):
        'Create an elementary matrix with the same rank of self'
        out=self.zeros()
        for i in self._range:
            out[i,i]=1
        return out

    def __bool__(self):
        'Return False when self is all-zeros'
        return not self.is_zeros()

    def _check_index(self, index):
        if any(x not in self._range for x in index):
            raise IndexError('BoolMatrix index out of range')

    def __getitem__(self, index):
        # self._check_index(index)
        return self.elements[self._offset(index)]

    def __setitem__(self, index, value):
        # self._check_index(index)
        # if value not in range(0,2):
        #     raise ValueError('value can only be 0 or 1')
        self.elements[self._offset(index)]=value

    def _offset(self, index):
        return index[0]*self.dimension+index[1]

    def __repr__(self):
        return '\n'.join(' '.join(str(self[i,j]) for j in self._range)
                for i in self._range)

    def __init__(self, dimension):
        'Create a N*N zerod BoolMatrix'
        self.dimension=dimension
        self.elements=array.ArrayType('B',[0]*dimension**2)
        self._range=range(dimension)

    def _vecmul(self, other):
        out=other.zeros()
        if not self or not other:
            return out
        for i in self._range:
            for k in self._range:
                # Note! other[k]!
                out[i] ^= self[i,k] & other[k]
        return out

    def zeros(self):
        return BoolMatrix(self.dimension)

    def _matmul(self, other):
        out=self.zeros()
        if not self or not other:
            return out
        for i in self._range:
            for j in self._range:
                for k in self._range:
                    # super slow O(n^3) loop
                    out[i,j] ^= self[i,k] & other[k,j]
        return out

    def __mul__(self, other):
        # effect performance
        # if self.dimension != other.dimension:
        #     raise ValueError('incompatible dimension')
        if isinstance(other, BoolMatrix):
            return self._matmul(other)
        return self._vecmul(other)

    def __pow__(self, p):
        if p == 0:
            return self.elementary()
        if p == 1:
            return self
        out,ans=self.elementary(),self
        while p > 0:
            if p & 1:
                out *= ans
            ans *= ans
            p >>= 1
        return out

class MatrixPowerCache:
    'Cache enough binary powers to accelerate power computation'

    def __init__(self, matrix, max_cache):
        '''max_cache should be the maximum power
        ever needs.'''
        self.matrix=matrix
        self.max_cache=max_cache
        self.cache=self.cache_binary_power()

    def cache_binary_power(self):
        'Compute M, M^2, M^4 ... M^(2^max_cache-1)'
        ans,out=self.matrix,[]
        for i in range(self.max_cache):
            out.append(ans)
            ans *= ans
        return out

    def power(self, p):
        '''Compute M^p with cache'''
        out=self.matrix.elementary()
        for n in iter_binary_power(p):
            out *= self.cache[n]
        return out

def iter_binary_power(p):
    'Iterate binary components'
    n=0
    while p > 0:
        if p & 1:
            yield n
        p >>= 1
        n+=1

def parse_input():
    # Note these digits aren't separated by spaces
    # line 1: dimension of matrix A
    N=int(input())
    # following N lines: condensed row each line
    rows=[[int(x) for x in input()] for _ in range(N)]
    # following 1 line: vector b
    vec=[int(x) for x in input()]
    # following 1 line: #powers k
    k=int(input())
    # following k lines: single number each line
    pows=[ int(input()) for _ in range(k) ]
    return (N,rows,vec,k,pows)

def handle_special_cases(k,b):
    for i in range(k):
        print(b)

def main():
    N,rows,vec,k,pows=parse_input()
    # Maximum binary powers to cache:
    max_binary_pow=round(math.log2(max(pows)))

    A=BoolMatrix.from_rows(N,rows)
    b=BoolVector(vec)

    # Useful logs:
    # logging.info('Matrix A:\n{}'.format(A))
    # logging.info('Vector b: {}'.format(b))
    # logging.info('powers: {}'.format(pows))

    # Handle some special cases
    if A.is_zeros():
        handle_special_cases(k,'0'*N)
        return
    if A.is_elementary():
        handle_special_cases(k, b)
        return

    c=MatrixPowerCache(A,max_binary_pow)
    for p in pows:
        # Slower version without cache
        # M=A**p
        M=c.power(p)
        vec=M*b
        print(vec)

if __name__=='__main__':
    # logging.basicConfig(level=logging.INFO)
    main()
