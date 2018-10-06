import datetime
import calendar

from sys import stdout

class DatetimeHelper:
    "helpers to format and parse datetime"
    FORMAT = '%Y%m%d%H%M'
    TIME_UNIT = datetime.timedelta(minutes=1)

    @classmethod
    def format(cls, dt):
        '''yyyymmddHHMM'''
        return dt.strftime(cls.FORMAT)

    @classmethod
    def parse(cls, string):
        return datetime.datetime.strptime(string, cls.FORMAT)

    @classmethod
    def tweak_weekday(cls, dt):
        'Tweak dt.weekday() so that Mon is 1, Sun is 0'
        return (dt.weekday()+1)%7

    @classmethod
    def make_weekday_abbr(cls):
        'Tweak day_abbr so that Sun Mon Tue...'
        names = list(calendar.day_abbr)
        names.insert(0, names.pop())
        return [s.lower() for s in names]

    @classmethod
    def make_month_abbr(cls):
        return [s.lower() for s in calendar.month_abbr]


class TimeSpecifier:
    pass

class CompoundTimeSpecifier(TimeSpecifier):
    '''Represent a (minute, hour, day, month, weekday) specifier.
    '''

    def __init__(self, minute, hour, day, month, weekday):
        self.minute=minute
        self.hour=hour
        self.day=day
        self.month=month
        self.weekday=weekday

    def match(self, dt):
        if not self.minute.match(dt.minute):
            return False
        if not self.hour.match(dt.hour):
            return False
        if not self.day.match(dt.day):
            return False
        if not self.month.match(dt.month):
            return False
        return self.weekday.match(DatetimeHelper.tweak_weekday(dt))

class ChoiceTimeSpecifier(TimeSpecifier):
    '''Represent a comma-separated choices that any of them
    can match.
    '''

    def __init__(self, iterable):
        self.choices = tuple(iterable)

    def match(self, val):
        return any(x.match(val) for x in self.choices)


class RangeTimeSpecifier(TimeSpecifier):
    '''Represent a range of time. Both start and finish are inclusive.
    '''

    def __init__(self, start, finish):
        self.start = start
        self.finish = finish

    def match(self, val):
        return self.start <= val <= self.finish

class AtomicTimeSpecifier(TimeSpecifier):
    '''Represent an atomic time specifier, a year/month/day/weekday.
    '''

    def __init__(self, val):
        self.val = val

    def match(self, val):
        return self.val == val

class StarTimeSpecifier(TimeSpecifier):
    ''' A '*', match anything anyway'''
    def match(self, val):
        return True

class CrontabEntryParser:
    '''Parse a line into a CrontabEntry'''

    WEEKDAY_ABBR = DatetimeHelper.make_weekday_abbr()
    MONTH_ABBR = DatetimeHelper.make_month_abbr()

    def parse(self, string):
        strings = string.split(' ')
        # Inline CrontabEntry
        return (self.parse_compound(strings[:-1]), strings[-1])

    def _parse_atomic(self, string):
        string=string.lower()
        if string in self.WEEKDAY_ABBR:
            return self.WEEKDAY_ABBR.index(string)
        elif string in self.MONTH_ABBR:
            return self.MONTH_ABBR.index(string)
        else:
            return int(string)

    def parse_atomic(self, string):
        return AtomicTimeSpecifier(self._parse_atomic(string))

    def parse_choices(self, string):
        return ChoiceTimeSpecifier(self.parse_range_or_atomic(c) for c in string.split(','))

    def parse_range_or_atomic(self, string):
        'range is not atomic!'
        if '-' in string:
            args = ( self._parse_atomic(x) for x in string.split('-') )
            return RangeTimeSpecifier(*args)
        else:
            return AtomicTimeSpecifier(self._parse_atomic(string))

    def parse_field(self, string):
        if string == '*':
            return StarTimeSpecifier()
        elif ',' in string:
            return self.parse_choices(string)
        else:
            return self.parse_atomic(string)

    def parse_compound(self, strings):
        '''Parse strings into a CompoundTimeSpecifier.
        Each field of the CompoundTimeSpecifier is defined as:

        field ::= star | choices | atomic
        choices ::= range_or_atomic (',' range_or_atomic)*
        star ::= '*'
        range_or_atomic = range | atomic
        range ::= atomic ('-' atomic)?
        atomic ::= int | weekday_abbr | month_abbr
        '''
        args = ( self.parse_field(s) for s in strings )
        return CompoundTimeSpecifier(*args)

class CrontabRunner:

    def __init__(self):
        inp = input().split()
        n_entries = int(inp[0])
        self.start = DatetimeHelper.parse(inp[1])
        self.finish = DatetimeHelper.parse(inp[2])
        p = CrontabEntryParser()
        # Inline CrontabTable
        self.table = tuple(p.parse(input()) for i in range(n_entries))

    def run(self):
        time = self.start
        while time < self.finish:
            for ent in self.table:
                # ent[0]: TimeSpecifier
                # ent[1]: cmd
                if ent[0].match(time):
                    stdout.write(f'{DatetimeHelper.format(time)} {ent[1]}\n')
            time += DatetimeHelper.TIME_UNIT


CrontabRunner().run()
