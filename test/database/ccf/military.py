def make_matrix(val, range_):
    return [[val for _ in range_] for _ in range_]

class Graph:
    'Graph with zero-based nodes'

    def __repr__(self):
        return '<Graph({})>'.format([list(map(int,x)) for x in
            self.adjacency])

    def __init__(self, N):
        self.N=N
        self.range=range(N)
        self.adjacency=make_matrix(False, self.range)

    def add_edge_one_based(self, u, v):
        self.adjacency[u-1][v-1]=True

    def has_edge(self, u, v)->bool:
        return self.adjacency[u][v]

    def iter_neighbours(self, u):
        for v in self.range:
            if self.adjacency[u][v]:
                yield v

class Reachability:

    def __repr__(self):
        return '<Reachability({})>'.format([list(map(int,x)) for x in
            self.reachability])

    def __init__(self, graph:Graph):
        self.graph=graph
        self.reachability=make_matrix(None, graph.range)
        for i in graph.range:
            self.reachability[i][i]=True
            for j in graph.range:
                if graph.has_edge(i,j):
                    self.reachability[i][j]=True
        for i in graph.range:
            self.init_with_dfs(i)

    def init_with_dfs(self, v):
        'Find all nodes reachable from ``v``'
        seen=set()
        def find_recursively(v, u):
            if self.reachability[v][u] is not None:
                # result computed
                return self.reachability[v][u]
            for n in self.graph.iter_neighbours(v):
                if n in seen:
                    continue
                seen.add(n)
                if find_recursively(n, u):
                    self.reachability[n][u]=True
                    return True
            self.reachability[v][u]=False
            return False
        for u in self.graph.range:
            if self.reachability[v][u] is None:
                self.reachability[v][u]=find_recursively(v,u)

    def reachable(self, u, v)->bool:
        return self.reachability[u][v]

    def make_know_count(self, N):
        knows=make_matrix(False, self.graph.range)
        for i in self.graph.range:
            for j in self.graph.range:
                if self.reachable(i,j):
                    knows[i][j]=True
                    knows[j][i]=True
        # Count the # of non-zero elements in a row
        get_knows=lambda row: len(list(filter(None, row)))
        # Count the # of counts that meet N
        return len([cnt for cnt in map(get_knows, knows) if cnt==N])


def parse_input():
    N,M=map(int,input().split())
    edges=[tuple(int(x) for x in input().split()) for i in range(M)]
    return (N,M,edges)

def main():
    N,M,edges=parse_input()
    graph=Graph(N)
    for u,v in edges:
        graph.add_edge_one_based(u,v)
    # print(graph)
    reachability=Reachability(graph)
    # print(reachability)
    count=reachability.make_know_count(N)
    print(count)

if __name__=='__main__':
    main()
