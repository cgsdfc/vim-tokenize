'''有趣的数 T<=1s'''

MODULOS=1000000007
ALL_DIGITS=tuple(range(4))

class Counter:
    'Count the #FunnyNumber whose bits is N'

    def __init__(self, nbits):
        self.nbits=nbits
        self.filled_count=[0 for d in ALL_DIGITS]
        self._count=0

    def count_nonused(self):
        return sum(1 for cnt in self.filled_count if cnt==0)

    def fill_bit(self, ith):
        if ith==self.nbits:
            if 0==self.count_nonused():
                self._count+=1
                if self._count == MODULOS:
                    self._count=0
            return
        for d in ALL_DIGITS:
            if d==0 and ith==self.nbits-1:
                # 最高位不可为0
                continue
            if d==1 and self.filled_count[0]:
                # 填了0不可再填1
                continue
            if d==3 and self.filled_count[2]:
                # 填了2不可再填3
                continue
            # 如果先填的还没填，那么后填的不可以填
            if d==0 and self.filled_count[1]==0:
                continue
            if d==2 and self.filled_count[3]==0:
                continue
            # 如果d已经填了至少一个，且剩余位置恰好等于未填的个数，则d不能填
            if self.filled_count[d] and self.count_nonused()==self.nbits-ith:
                continue
            # 如果d的数量到达了极限
            # if self.filled_count[d] == self.nbits-3:
            #     continue
            self.filled_count[d]+=1
            self.fill_bit(ith+1)
            self.filled_count[d]-=1

    @property
    def count(self):
        self.fill_bit(0)
        return self._count


if __name__=='__main__':
    N=int(input())
    assert N>=4
    print(Counter(N).count)
