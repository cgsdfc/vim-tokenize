from pprint import pprint as pp
from collections import defaultdict
from collections import namedtuple
from operator import itemgetter

def parse_input():
    N,K=map(int,input().split())
    lines=[tuple(int(x) for x in input().split()) for i in range(K)]
    return (N,lines)

class Event(namedtuple('Event', 'kind time keyid')):
    TAKE_KEY=0
    PUT_KEY=1

    @classmethod
    def gen_events(cls, lines):
        '''Generate events from ``lines``, which is (keyid,start_time,duration).
        Events happening at the same time are put together in a list.
        Return value is sorted by time.
        '''
        events=defaultdict(list)
        for keyid,start,len_ in lines:
            events[start].append(cls(cls.TAKE_KEY,start,keyid))
            stop=start+len_
            events[stop].append(cls(cls.PUT_KEY,stop,keyid))
        return sorted(events.items(),key=itemgetter(0))


class Keybox:
    def __repr__(self):
        return repr(self.box)

    def __init__(self, N):
        self.n_key=N
        self.box=[i+1 for i in range(N)]

    def handle_putkey(self, event):
        assert event.kind == event.PUT_KEY
        # 从左到右找到第一个空位放入钥匙
        pos=self.box.index(None)
        self.box[pos]=event.keyid

    def handle_takekey(self, event):
        assert event.kind == event.TAKE_KEY
        # 找到钥匙的位置并将其取出
        pos=self.box.index(event.keyid)
        self.box[pos]=None

    def handle_events(self, events):
        for _,evs in events:
            if len(evs) == 1:
                e=evs[0]
                if e.kind == Event.TAKE_KEY:
                    self.handle_takekey(e)
                else:
                    self.handle_putkey(e)
            else:
                if any(x.kind == x.PUT_KEY for x in evs):
                    putkeys=sorted([e for e in evs if e.kind == e.PUT_KEY],
                            key=lambda e: e.keyid)
                    for e in putkeys:
                        self.handle_putkey(e)
                for e in filter(lambda e: e.kind == e.TAKE_KEY, evs):
                    self.handle_takekey(e)

    def dump_state(self):
        # assert all(x is not None for x in self.box)
        print(' '.join(map(str,self.box)))

if __name__=='__main__':
    N,lines=parse_input()
    keybox=Keybox(N)
    events=Event.gen_events(lines)
    keybox.handle_events(events)
    keybox.dump_state()
