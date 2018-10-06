'''
问题描述：
问题描述
　　Alice和Bob正在玩井字棋游戏。
　　井字棋游戏的规则很简单：两人轮流往3*3的棋盘中放棋子，Alice放的是“X”，Bob放的是“O”，Alice执先。当同一种棋子占据一行、一列或一条对角线的三个格子时，游戏结束，该种棋子的持有者获胜。当棋盘被填满的时候，游戏结束，双方平手。
　　Alice设计了一种对棋局评分的方法：
　　- 对于Alice已经获胜的局面，评估得分为(棋盘上的空格子数+1)；
　　- 对于Bob已经获胜的局面，评估得分为 -(棋盘上的空格子数+1)；
　　- 对于平局的局面，评估得分为0；

    +---+---+---+
    | X | O | X |
    +---+---+---+
    | O | X | O |
    +---+---+---+
    | X |   |   |
    +---+---+---+


例如上图中的局面，Alice已经获胜，同时棋盘上有2个空格，所以局面得分为2+1=3。
　　由于Alice并不喜欢计算，所以他请教擅长编程的你，如果两人都以最优策略行棋，那么当前局面的最终得分会是多少？
输入格式
　　输入的第一行包含一个正整数T，表示数据的组数。
　　每组数据输入有3行，每行有3个整数，用空格分隔，分别表示棋盘每个格子的状态。0表示格子为空，1表示格子中为“X”，2表示格子中为“O”。保证不会出现其他状态。
　　保证输入的局面合法。(即保证输入的局面可以通过行棋到达，且保证没有双方同时获胜的情况)
　　保证输入的局面轮到Alice行棋。
输出格式
　　对于每组数据，输出一行一个整数，表示当前局面的得分。
样例输入
3
1 2 1
2 1 2
0 0 0
2 1 1
0 2 1
0 0 2
0 0 0
0 0 0
0 0 0
样例输出
3
-4
0
样例说明
　　第一组数据：
　　Alice将棋子放在左下角(或右下角)后，可以到达问题描述中的局面，得分为3。
　　3为Alice行棋后能到达的局面中得分的最大值。
　　第二组数据：

    +---+---+---+
    | O | X | X |
    +---+---+---+
    |   | O | X |
    +---+---+---+
    |   |   | O |
    +---+---+---+

Bob已经获胜(如图)，此局面得分为-(3+1)=-4。
　　第三组数据：
　　井字棋中若双方都采用最优策略，游戏平局，最终得分为0。
数据规模和约定
　　对于所有评测用例，1 ≤ T ≤ 5。
'''

class ChessBoard:
    '''
    Represent a 3*3 ChessBoard
    '''
    NumDims = 3
    EMPTY_PIECE = 0
    X_PIECE = 1
    O_PIECE = 2
    ALL_PIECES = (EMPTY_PIECE, X_PIECE, O_PIECE)
    ALL_NON_EMPTY_PIECES = (X_PIECE, O_PIECE)

    class Triple(tuple):
        '''
        Represent a vertical, horizontal or diagonal triple in the ChessBoard
        '''
        ROW = 0
        COL = 1
        MAIN_DIA = 2
        VICE_DIA = 3

        def __new__(cls, data, index, flag):
            self = super().__new__(cls, data)
            self.index = index
            self.flag = flag
            return self

        def GetEmptyLocation():
            '''
            Return the location of a piece given its index in the Triple
            '''
            index = self.index(ChessBoard.EMPTY_PIECE)
            if self.flag == self.ROW:
                return (self.index, index)
            if self.flag == self.COL:
                return (index, self.index)
            if self.flag == self.MAIN_DIA:
                return (index, index)
            # VICE_DIA
            return (index, -index-1)

        def __repr__(self):
            return 'ChessBoard.Triple(data={}, index={}, flag={})'\
                    .format(self.data, self.index, self.flag)

    def __init__(self, pieces):
        self.CheckPieces(pieces)
        self._board = pieces

    def PutPiece(self, slice_, piece):
        assert piece != self.EMPTY_PIECE
        assert self[slice_] == self.EMPTY_PIECE
        self[slice_] = piece

    def YieldTriples(self):
        for i, row in enumerate(self._board):
            yield self.Triple(row, i, self.Triple.ROW)
        for i in range(self.NumDims):
            yield self.Triple([self._board[i][j] for j in range(self.NumDims)],\
                    i, self.Triple.COL)
            yield self.Triple([self._board[j][j] for j in range(self.NumDims)],\
                    -1, self.Triple.MAIN_DIA)
            yield self.Triple([self._board[j][-j-1] for j in range(self.NumDims)],\
                    -1, self.Triple.VICE_DIA)

            @classmethod
    def CheckSlice(cls, slice_):
        assert isinstance(slice_, slice)
        assert slice_.start in range(cls.NumDims)
        assert slice_.stop in range(cls.NumDims)
        assert slice_.step == 1

    def __setitem__(self, slice_, val):
        self.CheckSlice(slice_)
        self._board[slice_.start][slice_.stop] = val

    def __getitem__(self, slice_):
        self.CheckSlice(slice_)
        return self._board[slice_.start][slice_.stop]

    @classmethod
    def CheckPieces(pieces):
        for x in pieces:
            assert len(x) == NumDims
            assert all(_ in ALL_PIECES for _ in x)
        return pieces

    @classmethod
    def FromStdin(cls):
        pieces = [input().split() for _ in range(NumDims)]
        assert len(pieces) == NumDims
        pieces = [[int(y) for y in x] for x in pieces]
        return cls(pieces)

    def ComputeScore(self, WinnerPiece):
        '''
        Compute score when the chess ends
        '''
        rng = range(self.NumDims)
        NumEmpties = sum(filter(lambda x:x == ChessBoard.EMPTY_PIECE,\
                (self._board[i][j] for i in rng for j in rng)))
        return NumEmpties+1 if WinnerPiece == ChessBoard.X_PIECE else -NumEmpties-1

class Player:
    '''
    Represent a player that always makes optimal moves
    '''
    WIN = 0
    LOSE = 1
    PEACE = 2
    CONTINUE = 3

    def __init__(self, MyPiece, ChessBoard_):
        self.MyPiece = MyPiece
        self.ChessBoard = ChessBoard_

    @property
    def MyPiece(self):
        return self._MyPiece

    @MyPiece.setter
    def MyPiece(self, mp):
        assert MyPiece in ChessBoard.ALL_NON_EMPTY_PIECES
        self._MyPiece = MyPiece

    @property
    def ChessBoard(self):
        return self._ChessBoard

    @ChessBoard.setter
    def ChessBoard(self, cb):
        assert isinstance(cb, ChessBoard)
        self._ChessBoard = cb


    def _WinShot(self, triple):
        '''
        +---+---+---+
        | X | X |   |
        +---+---+---+
        If this is our turn, we win
        '''
        return triple.count(self.MyPiece) == ChessBoard.NumDims-1\
                and triple.count(ChessBoard.EMPTY_PIECE) == 1

    def _NiceShort(self, triple):
        '''
        +---+---+---+
        | X |   |   |
        +---+---+---+
        Put in either empty place
        '''
        return triple.count(self.MyPiece) == 1 and triple.count(ChessBoard.EMPTY_PIECE)\
                == ChessBoard.NumDims-1

    def _GoodShort(self, triple):
        '''
        +---+---+---+
        |   |   |   |
        +---+---+---+
        Put in either empty place
        '''
        return triple.count(ChessBoard.EMPTY_PIECE) == ChessBoard.NumDims

    def _PlainShort(self, triple):
        '''
        Any empty place is ok
        '''
        return ChessBoard.EMPTY_PIECE in triple

    def MakeMove(self):
        '''
        Put MyPiece onto ChessBoard, return the status after
        this move (or game over)
        '''
        move = self._ChooseMove()
        if move[0] == Player.PEACE:
            return move[0]
        triple = move[1]
        loc = triple.GetEmptyLocation()
        self.ChessBoard.PutPiece(slice(*loc), self.MyPiece)
        return move[0]

    def _ChooseMove(self):
        AllTriples = list(self._ChessBoard.YieldTriples())
        for t in AllTriples:
            if self._WinShot(t):
                return (Player.WIN, t)
        for t in AllTriples:
            if self._NiceShort(t):
                return (Player.CONTINUE, t)
        for t in AllTriples:
            if self._GoodShort(t):
                return (Player.CONTINUE, t)
        for t in AllTriples:
            if self._PlainShort(t):
                return (Player.CONTINUE, t)
        return (Player.PEACE, None)


def PlayChess(_ChessBoard):
    AllPlayes = [Player(piece, _ChessBoard) for piece in ChessBoard.ALL_NON_EMPTY_PIECES]
    assert AllPlayes[0].MyPiece == ChessBoard.X_PIECE, 'Alice shots first! (X)'
    while all(p.MakeMove() == Player.CONTINUE):
        pass
    return _ChessBoard.ComputeScore()

def main():
    NumChessBoards = int(input())
    assert 1 <= NumChessBoards <= 5
    AllBoards = [ChessBoard.FromStdin() for _ in NumChessBoards]


