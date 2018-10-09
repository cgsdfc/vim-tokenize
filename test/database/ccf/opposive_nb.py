def main():
    N=int(input())
    numbers=[int(x) for x in input().split()]
    positives=set(filter(lambda x:x>0, numbers))
    negatives=list(filter(lambda x:x<0, numbers))
    print(sum(1 for n in negatives if -n in positives))

if __name__=='__main__':
    main()
