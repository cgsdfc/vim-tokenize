'''
问题描述：
　　URL 映射是诸如 Django、Ruby on Rails 等网页框架 (web frameworks) 的一个重要组件。对于从浏览器发来的 HTTP 请求，URL 映射模块会解析请求中的 URL 地址，并将其分派给相应的处理代码。现在，请你来实现一个简单的 URL 映射功能。
　　本题中 URL 映射功能的配置由若干条 URL 映射规则组成。当一个请求到达时，URL 映射功能会将请求中的 URL 地址按照配置的先后顺序逐一与这些规则进行匹配。当遇到第一条完全匹配的规则时，匹配成功，得到匹配的规则以及匹配的参数。若不能匹配任何一条规则，则匹配失败。
　　本题输入的 URL 地址是以斜杠 / 作为分隔符的路径，保证以斜杠开头。其他合法字符还包括大小写英文字母、阿拉伯数字、减号 -、下划线 _ 和小数点 .。例如，/person/123/ 是一个合法的 URL 地址，而 /person/123? 则不合法（存在不合法的字符问号 ?）。另外，英文字母区分大小写，因此 /case/ 和 /CAse/ 是不同的 URL 地址。
　　对于 URL 映射规则，同样是以斜杠开始。除了可以是正常的 URL 地址外，还可以包含参数，有以下 3 种：
　　字符串 <str>：用于匹配一段字符串，注意字符串里不能包含斜杠。例如，abcde0123。
　　整数 <int>：用于匹配一个不带符号的整数，全部由阿拉伯数字组成。例如，01234。
　　路径 <path>：用于匹配一段字符串，字符串可以包含斜杠。例如，abcd/0123/。
　　以上 3 种参数都必须匹配非空的字符串。简便起见，题目规定规则中 <str> 和 <int> 前面一定是斜杠，后面要么是斜杠，要么是规则的结束（也就是该参数是规则的最后一部分）。而 <path> 的前面一定是斜杠，后面一定是规则的结束。无论是 URL 地址还是规则，都不会出现连续的斜杠。
输入格式
　　输入第一行是两个正整数 n 和 m，分别表示 URL 映射的规则条数和待处理的 URL 地址个数，中间用一个空格字符分隔。
　　第 2 行至第 n+1 行按匹配的先后顺序描述 URL 映射规则的配置信息。第 i+1 行包含两个字符串 pi 和 ri，其中 pi 表示 URL 匹配的规则，ri 表示这条 URL 匹配的名字。两个字符串都非空，且不包含空格字符，两者中间用一个空格字符分隔。
　　第 n+2 行至第 n+m+1 行描述待处理的 URL 地址。第 n+1+i 行包含一个字符串 qi，表示待处理的 URL 地址，字符串中不包含空格字符。
输出格式
　　输入共 m 行，第 i 行表示 qi 的匹配结果。如果匹配成功，设匹配了规则 pj ，则输出对应的 rj。同时，如果规则中有参数，则在同一行内依次输出匹配后的参数。注意整数参数输出时要把前导零去掉。相邻两项之间用一个空格字符分隔。如果匹配失败，则输出 404。
样例输入
5 4
/articles/2003/ special_case_2003
/articles/<int>/ year_archive
/articles/<int>/<int>/ month_archive
/articles/<int>/<int>/<str>/ article_detail
/static/<path> static_serve
/articles/2004/
/articles/1985/09/aloha/
/articles/hello/
/static/js/jquery.js
样例输出
year_archive 2004
article_detail 1985 9 aloha
404
static_serve js/jquery.js
样例说明
　　对于第 1 个地址 /articles/2004/，无法匹配第 1 条规则，可以匹配第 2 条规则，参数为 2004。
　　对于第 2 个地址 /articles/1985/09/aloha/，只能匹配第 4 条规则，参数依次为 1985、9（已经去掉前导零）和 aloha。
　　对于第 3 个地址 /articles/hello/，无法匹配任何一条规则。
　　对于第 4 个地址 /static/js/jquery.js，可以匹配最后一条规则，参数为 js/jquery.js。
数据规模和约定
　　1 ≤ n ≤ 100，1 ≤ m ≤ 100。
　　所有输入行的长度不超过 100 个字符（不包含换行符）。
　　保证输入的规则都是合法的。
'''

import re

NO_MATCH_404 = '404'

PHD2REGEX = (
        ('<int>', r'(\d+)'),
        ('<str>', r'([^/]+)'),
        ('<path>', r'(.*)'))

class UrlRule:
    '''
    Represent a url rule, which is a under the notion of url pattern.
    The place holder (<int>, <str>, e.g.) in the `pattern` is replaced with regex with the corresponding
    names. When a url match the rule, its place holder can be retrieved.
    '''

    def __init__(self, pat, name):
        for plhr in PHD2REGEX:
            pat = pat.replace(plhr[0], plhr[1])
        self._pattern = re.compile('^{}$'.format(pat))
        self._name = name

    def __repr__(self):
        return 'UrlRule(name={}, pattern={})'.format(self._name, self._pattern)

    def Match(self, url):
        '''
        Match a url string, return a MatchResult
        '''
        matobj = self._pattern.match(url)
        return MatchResult(self._name, matobj.groups())\
                if matobj else MatchResult()

class MatchResult:
    '''
    Hold the Result of a match.
    Also responsible for the formatting jobs.
    '''
    def __init__(self, name=None, group=None):
        '''
        name: the name of the rule
        group: a list of matched place holders
        '''
        self._name = name
        self._group = group

    def __repr__(self):
        return str(self._group) if self else NO_MATCH_404

    def __bool__(self):
        '''
        Whether self is a successful match
        '''
        return self._name is not None

    def __str__(self):
        '''
        Format self
        '''
        if not self:
            return NO_MATCH_404
        def strip_leading_zero(x):
            try:
                x = int(x)
            except ValueError:
                pass
            finally:
                return str(x)

        items = ' '.join(map(strip_leading_zero, self._group))
        return '{name} {items}'.format(name=self._name, items=items)

class UrlMatcher:
    '''
    Hold a set of UrlRules and perform a match of a concrete url against the rules.
    '''
    def __init__(self, iterable):
        '''
        iterable must be of (pattern, name) tuples
        '''
        self._all_rules = [UrlRule(*args) for args in iterable]

    def Parse(self, url):
        for r in self._all_rules:
            Result = r.Match(url)
            if Result: return Result
        return Result

    def PrintAllRule(self):
        for _ in self._all_rules:
            print(_)

def main():
    NumRules, NumUrls = map(int, input().split())
    assert 1 <= NumRules <= 100
    assert 1 <= NumUrls <= 100
    Matcher = UrlMatcher(input().split() for _ in range(NumRules))
    # Matcher.PrintAllRule()
    Result = [ Matcher.Parse(input()) for _ in range(NumUrls)]
    # print('\n'.join(['{!r}'.format(_) for _ in Result]))
    print(*Result, sep="\n")


if __name__ == '__main__':
    main()
