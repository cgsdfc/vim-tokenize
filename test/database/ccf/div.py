parse_line=lambda: [ int(x) for x in input().split() ]

def parse_input():
    N,M=map(int,input().split())
    numbers=parse_line()
    assert len(numbers)==N
    return (numbers,M)

def iter_operations(M):
    for i in range(M):
        yield parse_line()

def main():
    numbers,M=parse_input()
    # The annoying 1-based
    for op in iter_operations(M):
        if op[0] == 1:
            # Inline
            l,r,v=op[1:]
            for i in range(l-1,r):
                nb=numbers[i]
                if nb % v == 0:
                    numbers[i]=nb // v
        else:
            # Inline
            l,r=op[1:]
            print(sum(numbers[i] for i in range(l-1,r)))

if __name__=='__main__':
    main()
