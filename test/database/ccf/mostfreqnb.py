from collections import Counter
from operator import itemgetter

def main():
    N=int(input())
    numbers=[int(x) for x in input().split()]
    c=Counter(numbers)
    max_freq=c.most_common(1)[0][1]
    most_freq_items=( x for x in c.items() if x[1]>=max_freq )
    min_val=min(most_freq_items, key=itemgetter(0))[0]
    print(min_val)

if __name__=='__main__':
    main()
