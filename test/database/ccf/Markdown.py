import re
import enum

class BlockEnum(enum.Enum):
    PARAGRAPH = 1
    HEADING = 2
    ITEM_LIST = 3

class InlineEnum(enum.Enum):
    EMPHASIZED = 1
    HYPERLINK = 2
    PLAIN_TEXT = 3

class BlockIterator:
    'Fetch blocks from lines'
    # Patterns to match individual construct.
    BLANK_LINE = re.compile(r'^\s*$')
    HEADING = re.compile(r'^(?P<sharps>#+)(?P<content>.*)$')
    ITEM_LIST = re.compile(r'^\*\s+(?P<content>.*)$')

    def __init__(self, lines):
        # The lines we are iterating over
        self.lines = iter(lines)
        # If not None, it is the class where we are inside
        self.inside_block = None
        # If we are inside a block, buffer to collect lines
        self.buffer = []

    def _yield_buffer(self):
        'Also reset buffer and inside_block'
        yield (self.inside_block, self.buffer)
        self.inside_block = None
        self.buffer = []

    def __iter__(self):
        while 1:
            try:
                line = next(self.lines)
            except StopIteration:
                if self.inside_block:
                    self._yield_buffer()
                raise GeneratorExit
            if self.BLANK_LINE(line):
                if self.inside_block:
                    self._yield_buffer()
            elif self.HEADING.match(line):
                yield (BlockEnum.HEADING, line)
            elif self.ITEM_LIST.match(line):
                self.inside_block = BlockEnum.ITEM_LIST
                self.buffer.append(line)
            else:
                self.inside_block = BlockEnum.PARAGRAPH
                self.buffer.append(line)


class InlineIterator:
    'Fetch inline element from a line'
    HYPERLINK = re.compile(r'\[(?P<text>.*?)\]\((?P<link>.*?)\)')
    EMPHASIZED = re.compile(r'_(?P<text>.*?)_')

    def __init__(self, line):
        self.line = line
        self.pos = 0
        self.len = len(line)
        self.buffer = []

    def _yield_buffer(self):
        yield (InlineEnum.PLAIN_TEXT, self.line[self.textpos: self.pos-1])


    def __iter__(self):
        while self.pos < self.len
            char = self.line[self.pos]
            if char == '[':
                self._yield_buffer()
                mat = self.HYPERLINK.search(self.line, self.pos)
                yield (InlineEnum.HYPERLINK, mat)
                self.pos = mat.end()
            elif char == '_':
                mat = self.EMPHASIZED.search(self.line, self.pos)
                yield (InlineEnum.EMPHASIZED, mat)
                self.pos = mat.end()
            else:
                self.buffer.append(
                

                



class MarkdownParser:

    # States
    PARA_BEGIN = 0

    def parse_next_block(self, lines):
        pass

                   


