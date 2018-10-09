from pprint import pprint as pp
from collections import defaultdict
from collections import namedtuple
from collections import deque as Queue
from operator import itemgetter

EXPRESS=0 # 大路
HIGHWAY=1 # 小路

def compute_weight(distance, type_):
    'Compute weight given distance and type_'
    if type_ == EXPRESS:
        return distance
    assert type_==HIGHWAY
    return distance**2

def parse_input():
    n,m=map(int, input().split())
    edges=[tuple(int(x) for x in input().split()) for i in range(m)]
    return (n,m,edges)

class Edge:
    def __init__(self, node, distance, type_=None):
        self.distance=distance
        self.type_=type_
        self.node=node

    def __repr__(self):
        return '<Edge(node={},distance={},type_={})>'.format(
                self.node,
                self.distance,
                self.type_)

class Graph:
    def __init__(self, N):
        self.N=N
        self.adjacent_list=defaultdict(list)
        self.has_edge=set()

    def __repr__(self):
        return tuple(self.adjacent_list.items())

    def iter_nodes(self):
        for i in range(self.N):
            yield i+1

    def add_edge(self, u, v, distance, type_=None):
        if (u,v, type_) in self.has_edge:
            return

        self.has_edge.add((u,v, type_))
        self.has_edge.add((v,u, type_))

        e=Edge(node=v,distance=distance,type_=type_)
        self.adjacent_list[u].append(e)

        e=Edge(node=u,distance=distance,type_=type_)
        self.adjacent_list[v].append(e)

    def iter_edges(self, v):
        '''Iterate edges associated with ``v``.'''
        return self.adjacent_list[v]

    def shortest_distance(self):
        'Shortest distance from 1 to N'
        return self.dijkstra(1)[self.N]['weight']

    def dijkstra(self, start)->dict:
        '''Dijkstra algorithm.
        Return shortest distance from ``start`` to all nodes.
        '''
        seen=set()
        seen.add(start)
        distance={}
        for e in self.iter_edges(start):
            distance[e.node]={
                'type_': e.type_, # The type_ of edges leading to this node
                'weight': compute_weight(e.distance, e.type_), # minimum weight
                'distance': e.distance, # the distance of edges leading to this node
                'parent': start,
            }

        for i in range(self.N-1):
            min_v,min_info=min(filter(
                lambda x: x[0] not in seen, distance.items()),
                key=lambda x:x[1]['weight']
            )
            seen.add(min_v)
            for e in self.iter_edges(min_v):
                u=e.node # Shortcut
                if u in seen:
                    continue
                if min_info['type_'] == e.type_:
                    type_change=False
                    if e.type_ == EXPRESS:
                        # Fast
                        dist=min_info['weight']+e.distance
                    else:
                        # w'=w-a^2+(a+b)^2=w+b^2+2ab=w+b(b+2a)
                        dist=min_info['weight']+e.distance*(e.distance+2*min_info['distance'])
                else:
                    type_change=True
                    dist=min_info['weight']+compute_weight(e.distance,e.type_)
                if u not in distance or dist < distance[u]['weight']:
                    distance[u]={
                        'type_': e.type_,
                        'distance': e.distance + (0 if type_change else
                            min_info['distance']),
                        'weight': dist,
                        'parent': min_v,
                    }
        return distance


    @classmethod
    def build(cls, n, edges):
        '''Build the graph from ``edges``.'''
        graph=cls(n)
        for t,a,b,c in edges:
            graph.add_edge(a,b,c,t)
        return graph

def main():
    n,m,edges=parse_input()
    graph=Graph.build(n,edges)
    # pp(sorted(list(graph.has_edge),key=itemgetter(2)))
    # pp(graph.dijkstra(1))
    print(graph.shortest_distance())

if __name__=='__main__':
    main()
