IGNORED='IGNORED'

def parse_input():
    N,M=map(int, input().split())
    wins=[[int(x) for x in input().split()] for i in range(N)]
    clicks=[[int(x) for x in input().split()] for i in range(M)]
    return (N,M,wins,clicks)

class WinStack:
    def __init__(self, wins):
        # 注意：窗口本身有编号，初始给定，不随其顺序而改变
        self.wins=[(i,(x1,x2),(y1,y2)) for i,(x1,y1,x2,y2) in enumerate(wins,1)]

    def __repr__(self):
        return repr(self.wins)

    def click(self, pos):
        for i, w in enumerate(reversed(self.wins)):
            if self.in_window(w[1:], pos):
                selected=len(self.wins)-1-i
                t=self.wins[selected]
                self.wins[selected]=self.wins[-1]
                self.wins[-1]=t
                return w[0]
        return IGNORED

    def in_window(self, win, pos):
        return all(r[0]<=x<=r[1] for x,r in zip(pos, win))


def main():
    N,M,wins,clicks=parse_input()
    winstack=WinStack(wins)
    for pos in clicks:
        print(winstack.click(pos))

main()
