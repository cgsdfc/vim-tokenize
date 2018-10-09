import logging
logger=logging.getLogger()

def main():
    # n: #cakes, k: least weight
    n,k=[int(x) for x in input().split()]
    # cakes: the weights of cakes from 1 to n
    cakes=[ int(x) for x in input().split() ]
    # count: #friends that get cakes
    count=0
    # i: current available cake
    i=0
    logger.info('config: #cakes {}, least-weight {}'.format(n,k))
    logger.info('weights of cakes: {}'.format(cakes))
    while i<n:
        j=i
        alloc=0
        while j<n and alloc<k:
            alloc+=cakes[j]
            j+=1
        friend='friend {}'.format(count)
        # don't get 1-1
        logger.info('{} gets cakes {}'.format(friend,
            '{}-{}'.format(i+1,j) if i+1!=j else j))
        logger.info('{} gets weights {}'.format(friend, alloc))
        count+=1
        i=j
        logger.info('cakes left: {}'.format(n-i))
    print(count)

if __name__=='__main__':
    # logging.basicConfig(level=logging.INFO)
    main()
