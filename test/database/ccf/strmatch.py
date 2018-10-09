import re

def main():
    string=input()
    matchcase=int(input())
    if matchcase:
        regex=re.compile(string)
    else:
        regex=re.compile(string, re.I)
    N=int(input())
    res=[line for line in (input() for i in range(N)) if
            regex.search(line)]
    for l in res:
        print(l)


if __name__=='__main__':
    main()
