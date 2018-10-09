'''
>>> 5 2
3
>>> 7 3
4
'''

def you_are_out(n, k):
    return n % k == 0 or k == int(str(n)[-1])

def main():
    N, K = [ int(x) for x in input().split() ]
    players = [ i+1 for i in range(N) ]
    count = 1
    next_ = 0
    while len(players) > 1:
        v = players[next_]
        if you_are_out(count, K):
            # print('count {}, player {} out'.format(count, v))
            del players[next_]
            if next_ == len(players):
                # the last one has no *next one* to replace it.
                next_ = 0
        else:
            next_ = (next_+1) % len(players)
        count += 1

    print(players[0])

if __name__ == '__main__':
    main()
