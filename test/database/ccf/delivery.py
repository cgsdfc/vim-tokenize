from pprint import pprint as pp
from collections import deque

class Queue:
    '''Simple FIFO queue'''
    def __init__(self):
        self._queue=deque()

    def put(self, item):
        return self._queue.append(item)

    def get(self):
        return self._queue.popleft()

    def __repr__(self):
        return repr(self._queue).replace('deque', 'Queue')

    def __len__(self):
        return len(self._queue)

def parse_coordinates(N):
    '''Parse N lines, each of which is ``x y`` and becomes ``(x, y)``.
    Return a list of parsed corrdinates.
    '''
    return [tuple(int(c) for c in input().split()) for i in range(N)]

def parse_input():
    '''Parse input.
    Return a 4-tuple: ``(N, shops, clients, barriers)``, where
    N: dimension of the map.
    shops: a list of coordinates of shops.
    clients: a list of clients, each of which is ``(location, orders)``.
    barriers: a list of corrdinates of barriers (blocked locations).
    '''

    n,m,k,d=map(int, input().split())
    shops=parse_coordinates(m)
    clients=[((x,y),cnt) for x,y,cnt in (map(int, input().split())
        for i in range(k))]
    barriers=parse_coordinates(d)
    return (n,shops,clients,barriers)

def process_clients(clients):
    '''Merge orders from clients of the same locations.'''
    from collections import defaultdict
    res=defaultdict(int)
    for c in clients:
        res[c[0]]+=c[1]
    return res.items()

class Graph:
    ALL_DIRS=((0,1),(0,-1),(1,0),(-1,0))

    def __repr__(self):
        return '<Graph {0}*{0}>'.format(self.N)

    def __init__(self, N, barriers):
        self.N=N
        self.barriers=set(barriers)
        self.valid_range=range(1,N+1)

    def iter_neighbors(self, location):
        'Iterate the neighbors of ``location`` avoiding barriers'
        for delta in self.ALL_DIRS:
            res=tuple(x+dx for x,dx in zip(location, delta))
            if any(x not in self.valid_range for x in res):
                continue
            if res in self.barriers:
                continue
            yield res

    def bfs(self, start, stop):
        'Compute the shortest distance from ``start`` to ``stop`` using BFS'
        if start in self.barriers or stop in self.barriers:
            raise ValueError('start and stop should not be barrier')
        if start == stop:
            return 0
        q=Queue()
        # distance is the key point of bfs
        distance={start:0}
        q.put(start)
        while q:
            head=q.get()
            if head == stop:
                return distance[stop]
            for nb in self.iter_neighbors(head):
                if nb in distance:
                    continue
                distance[nb]=distance[head]+1
                q.put(nb)
        # stop is not reachable from start, return None

    def shortest_distance(self, sources, target):
        '''Compute the shortest distance from multiple sources to one target.
        '''
        return min(filter(None, map(lambda src: self.bfs(src, target), sources)))

def clients_prices(graph, clients, shops):
    '''Compute the total prices for delivering from ``shops`` to all ``clients``.
    Price = Order * Distance
    '''
    return sum(graph.shortest_distance(shops, c[0])*c[1] for c in clients)

def main():
    N,shops,clients,barriers=parse_input()
    clients=process_clients(clients)
    graph=Graph(N,barriers)
    # print(graph.bfs((8,8),(1,1)))
    print(clients_prices(graph,clients,shops))
    # try:
        # print(clients_prices(graph,clients,shops))
    # except:
        # print(0)

if __name__=='__main__':
    main()
