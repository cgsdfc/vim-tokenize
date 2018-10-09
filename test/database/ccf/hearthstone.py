import re
import logging
logger=logging.getLogger(__file__)

class Character:
    def __init__(self, health, attack_power):
        self.health=health
        self.attack_power=attack_power

    def is_dead(self):
        return self.health<=0

class Hero(Character):
    INIT_HEALTH=30
    INIT_ATTACK_POW=0

    def __init__(self):
        super().__init__(self.INIT_HEALTH, self.INIT_ATTACK_POW)

class Server(Character):
    def attack(self, other):
        self.health -= other.attack_power
        other.health -= self.attack_power

    def __repr__(self):
        return '<Server(health={},attack_power={})>'.format(self.health,
                self.attack_power)

class Player:
    SERVERS_MAX=7

    def __init__(self, ID):
        self.hero=Hero()
        self.servers=[]
        self.ID=ID

    def __repr__(self):
        return '<Player({})>'.format(self.ID)

    def summon(self, position, attack_power, health):
        server=Server(health, attack_power)
        self.servers.insert(position-1, server)
        logger.info('{} summon {} at pos {}'.format(self, server, position))

    def get_server(self, serid)->Server:
        '''``serid`` is [1,7], return the corresponding server.'''
        assert serid in range(1,8)
        return self.servers[serid-1]

    def get_defender(self, defid):
        return self.hero if defid==0 else self.get_server(defid)

    def attack(self, attid, defid, other):
        assert attid in range(1,8)
        assert defid in range(0,8)

        logger.info('{}\'s {} attacked {}\'s {}'
                .format(self, attid, other, defid))

        attacker=self.get_server(attid)
        defender=other.get_defender(defid)
        attacker.attack(defender)

        if attacker.is_dead():
            self.clear_server(attid)
        if defender.is_dead() and isinstance(defender,Server):
            other.clear_server(defid)

    def clear_server(self, serid):
        assert serid in range(1,8)
        self.servers.pop(serid-1)
        logger.info('{} server {} dead'.format(self, serid))

    def is_lose(self):
        return self.hero.is_dead()

    def dump(self):
        print(self.hero.health)
        print('{} {}'.format(len(self.servers), ' '.join(str(s.health) for
            s in self.servers)) if len(self.servers) else '0')

class Game:
    SUMMON=re.compile(
            r'summon (?P<position>[1-7]) (?P<attack_power>\d+) (?P<health>\d+)')
    ATTACK=re.compile(r'attack (?P<attid>[1-7]) (?P<defid>[0-7])')

    def __init__(self):
        self.players=[Player(i) for i in range(2)]
        # 先手玩家
        self.current=self.players[0]
        # 后手玩家
        self.opponent=self.players[1]

    def run(self, actions):
        parse_args=lambda m: map(int, m.groups())

        for act in actions:
            match=self.SUMMON.match(act)
            if match:
                # groups() starts from 1
                self.current.summon(*parse_args(match))
                continue
            match=self.ATTACK.match(act)
            if match:
                args=parse_args(match)
                self.current.attack(*args, other=self.opponent)
                continue
            else:
                # assert act == 'end'
                self.swap_players()

    def swap_players(self):
        logger.info('swap_players')
        t=self.current
        self.current=self.opponent
        self.opponent=t

    def show_result(self):
        if self.players[0].is_lose():
            res=-1
        elif self.players[1].is_lose():
            res=1
        else:
            res=0
        print(res)
        for p in self.players:
            p.dump()

def main():
    # logging.basicConfig(level=logging.INFO)
    n=int(input())
    actions=[input() for i in range(n)]
    g=Game()
    g.run(actions)
    g.show_result()

if __name__=='__main__':
    main()
