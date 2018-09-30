'''Hope this is just a simple practice using
the standard library json.
'''

import json

def do_query(json_obj, query):
    query = query.split('.')
    obj = json_obj
    for key in query:
        try:
            obj = obj[key]
        except:
            print('NOTEXIST')
            return
    if isinstance(obj, str):
        print('STRING {}'.format(obj))
    else:
        print('OBJECT')

def main():
    n_lines, n_queries = map(int, input().split())
    string = ''.join(input() for _ in range(n_lines))
    json_obj = json.loads(string)
    queries = [input() for _ in range(n_queries)]
    for query in queries:
        do_query(json_obj, query)


if __name__ == '__main__':
    main()
