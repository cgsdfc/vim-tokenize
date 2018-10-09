import re
ISBN=re.compile(r'(\d-\d{3}-\d{5})-(?P<code>\d|X)')
MOD=11
RIGHT='Right'

def main():
    match=ISBN.match(input())
    digits=[int(x) for x in match.group(1).replace('-','')]
    assert len(digits)==9
    code=sum(i*d for i,d in enumerate(digits,1))%MOD
    code='X' if code==10 else str(code)
    given=match.group('code')
    if given == code:
        print(RIGHT)
    else:
        print('{}-{}'.format(match.group(1),code))

main()
