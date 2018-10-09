'''
问题描述
　　数轴上有一条长度为L（L为偶数)的线段，左端点在原点，右端点在坐标L处。有n个不计体积的小球在线段上，开始时所有的小球都处在偶数坐标上，速度方向向右，速度大小为1单位长度每秒。
　　当小球到达线段的端点（左端点或右端点）的时候，会立即向相反的方向移动，速度大小仍然为原来大小。
　　当两个小球撞到一起的时候，两个小球会分别向与自己原来移动的方向相反的方向，以原来的速度大小继续移动。
　　现在，告诉你线段的长度L，小球数量n，以及n个小球的初始位置，请你计算t秒之后，各个小球的位置。
提示
　　因为所有小球的初始位置都为偶数，而且线段的长度为偶数，可以证明，不会有三个小球同时相撞，小球到达线段端点以及小球之间的碰撞时刻均为整数。
　　同时也可以证明两个小球发生碰撞的位置一定是整数（但不一定是偶数）。
输入格式
　　输入的第一行包含三个整数n, L, t，用空格分隔，分别表示小球的个数、线段长度和你需要计算t秒之后小球的位置。
　　第二行包含n个整数a1, a2, …, an，用空格分隔，表示初始时刻n个小球的位置。
输出格式
　　输出一行包含n个整数，用空格分隔，第i个整数代表初始时刻位于ai的小球，在t秒之后的位置。
样例输入
3 10 5
4 6 8
样例输出
7 9 9

样例输入
10 22 30
14 12 16 6 10 2 8 20 18 4
样例输出
6 6 8 2 4 0 4 12 10 2
数据规模和约定
　　对于所有评测用例，1 ≤ n ≤ 100，1 ≤ t ≤ 100，2 ≤ L ≤ 1000，0 < ai < L。L为偶数。
　　保证所有小球的初始位置互不相同且均为偶数。
'''

class Ball:
    def __init__(self, pos, index):
        self.pos = pos
        self.dir = DIR_RIGHT
        self.index = index
        self.nextdir = self.dir

    def __repr__(self):
        return 'Ball(pos={}, dir={})'.format(self.pos, self.dir)

    def __str__(self):
        return self.__repr__()

    def HitWall(self):
        return (self.pos == 0 and self.dir == DIR_LEFT) or \
                (self.pos == LenOfLine and self.dir == DIR_RIGHT)

    def _HitNeighborDisZero(self, neighbor):
        '''
        When 2 balls are in the same position and have different directions,
        they collide with each other.
        '''
        return self.dir != neighbor.dir and self.pos == neighbor.pos

    def _HitNeighborDisOne(self, neighbor):
        '''
        When 2 balls move towards each other at moment t and their distance
        is 1 unit, they are supposed to turn their head back **before** ever
        run into each other. This is because the puzzle says if 2 balls would
        collide, it must happen at integral unit (as opposed to 1/2).

        The above situation can be depicted as
        A->   <-B
        |<--1-->|
        This can happen with `data3`, where A is left with 1 unit to reach the right border
        when B is just rebounding right from the right border. A and B are in the above situation
        since their distance is 1 unit and they face each other.

        In this situation, we let turn back immediately.
        '''
        return self.pos+1 == neighbor.pos and self.dir == DIR_LEFT and neighbor.dir == DIR_RIGHT or\
                self.pos-1 == neighbor.pos and self.dir == DIR_RIGHT and neighbor.dir == DIR_LEFT

    def _HitNeighbor(self, neighbor):
        return self._HitNeighborDisZero(neighbor) or self._HitNeighborDisOne(neighbor)

    def IsHitting(self):
        if self.HitWall():
            return True
        if self.dir == DIR_LEFT:
            return self.index > 0 and self._HitNeighbor(AllBalls[self.index-1])
        return self.index < NumBalls-1 and self._HitNeighbor(AllBalls[self.index+1])

    def ChangeNextDir(self):
        if self.IsHitting():
            # Flip the dir if we are hitting.
            self.nextdir = DIR_RIGHT if self.dir == DIR_LEFT else DIR_LEFT
        else:
            self.nextdir = self.dir

    def ChangeDir(self):
        self.dir = self.nextdir

    def Move(self):
        self.pos += ( 1 if self.dir == DIR_RIGHT else -1 )

def PrintAllPos():
    print(' '.join([ str(ball.pos) for ball in AllBalls ]))

DIR_LEFT = -1
DIR_RIGHT = 1
NumBalls, LenOfLine, TotalTime = map(int, input().split())
AllBalls = [Ball(int(init_pos), index)\
        for index, init_pos in enumerate(input().split())]

# 确保前提
assert 1 <= NumBalls <= 100 and 1 <= TotalTime <= 100 and 2 <= LenOfLine <= 1000
assert NumBalls == len(AllBalls), 'NumBalls must match'
assert LenOfLine % 2 == 0, 'LenOfLine must be even'
SeenPos = {}
def CheckInitPos(pos):
    assert pos % 2 == 0
    assert 0 < pos < LenOfLine
    assert pos not in SeenPos
    SeenPos[pos] = 1
map(CheckInitPos, AllBalls)

# What if hitting the wall happens at the same time when
# hitting upcoming neighbor?

# 开始模拟
for t in range(TotalTime):
    PrintAllPos()
    [b.Move() for b in AllBalls]
    [b.ChangeNextDir() for b in AllBalls]
    [b.ChangeDir() for b in AllBalls]

PrintAllPos()
