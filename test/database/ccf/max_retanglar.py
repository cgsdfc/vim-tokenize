# def main():
#     Ln=[0]*N
#     Rn=[0]*N
#     for i,j in zip(range(1,N), range(N-2,-1,-1)):
#         if Hn[i]<=Hn[i-1]:
#             Ln[i]=Ln[i-1]+1
#         if Hn[j]<=Hn[j+1]:
#             Rn[j]=Rn[j+1]+1
#     res=max(Hn[i]*(Rn[i]+Ln[i]+1) for i in range(N))
#     print('Rn={}'.format(Rn))
#     print('Ln={}'.format(Ln))
#     print(res)

def parse_input():
    N=int(input())
    Hn=[int(x) for x in input().split()]
    return (N,Hn)

# 暴力法居然过了，可见N没有1000这么多。
def main():
    N,Hn=parse_input()
    Wn=[0]*N
    for i in range(N):
        for k in range(i-1, -1, -1):
            if Hn[k]>=Hn[i]:
                Wn[i]+=1
            else:
                break
        for k in range(i+1,N):
            if Hn[k]>=Hn[i]:
                Wn[i]+=1
            else:
                break
    res=max((1+Wn[i])*Hn[i] for i in range(N))
    print(res)


if __name__=='__main__':
    main()
