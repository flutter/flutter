#=======================================================================
#
#   Python Lexical Analyser
#
#   Traditional Regular Expression Syntax
#
#=======================================================================

from Regexps import Alt, Seq, Rep, Rep1, Opt, Any, AnyBut, Bol, Eol, Char
from Errors import PlexError

class RegexpSyntaxError(PlexError):
  pass

def re(s):
  """
  Convert traditional string representation of regular expression |s|
  into Plex representation.
  """
  return REParser(s).parse_re()

class REParser(object):

  def __init__(self, s):
    self.s = s
    self.i = -1
    self.end = 0
    self.next()

  def parse_re(self):
    re = self.parse_alt()
    if not self.end:
      self.error("Unexpected %s" % repr(self.c))
    return re

  def parse_alt(self):
    """Parse a set of alternative regexps."""
    re = self.parse_seq()
    if self.c == '|':
      re_list = [re]
      while self.c == '|':
        self.next()
        re_list.append(self.parse_seq())
      re = Alt(*re_list)
    return re

  def parse_seq(self):
    """Parse a sequence of regexps."""
    re_list = []
    while not self.end and not self.c in "|)":
      re_list.append(self.parse_mod())
    return Seq(*re_list)

  def parse_mod(self):
    """Parse a primitive regexp followed by *, +, ? modifiers."""
    re = self.parse_prim()
    while not self.end and self.c in "*+?":
      if self.c == '*':
        re = Rep(re)
      elif self.c == '+':
        re = Rep1(re)
      else: # self.c == '?'
        re = Opt(re)
      self.next()
    return re

  def parse_prim(self):
    """Parse a primitive regexp."""
    c = self.get()
    if c == '.':
      re = AnyBut("\n")
    elif c == '^':
      re = Bol
    elif c == '$':
      re = Eol
    elif c == '(':
      re = self.parse_alt()
      self.expect(')')
    elif c == '[':
      re = self.parse_charset()
      self.expect(']')
    else:
      if c == '\\':
        c = self.get()
      re = Char(c)
    return re

  def parse_charset(self):
    """Parse a charset. Does not include the surrounding []."""
    char_list = []
    invert = 0
    if self.c == '^':
      invert = 1
      self.next()
    if self.c == ']':
      char_list.append(']')
      self.next()
    while not self.end and self.c != ']':
      c1 = self.get()
      if self.c == '-' and self.lookahead(1) != ']':
        self.next()
        c2 = self.get()
        for a in xrange(ord(c1), ord(c2) + 1):
          char_list.append(chr(a))
      else:
        char_list.append(c1)
    chars = ''.join(char_list)
    if invert:
      return AnyBut(chars)
    else:
      return Any(chars)

  def next(self):
    """Advance to the next char."""
    s = self.s
    i = self.i = self.i + 1
    if i < len(s):
      self.c = s[i]
    else:
      self.c = ''
      self.end = 1

  def get(self):
    if self.end:
      self.error("Premature end of string")
    c = self.c
    self.next()
    return c

  def lookahead(self, n):
    """Look ahead n chars."""
    j = self.i + n
    if j < len(self.s):
      return self.s[j]
    else:
      return ''

  def expect(self, c):
    """
    Expect to find character |c| at current position.
    Raises an exception otherwise.
    """
    if self.c == c:
      self.next()
    else:
      self.error("Missing %s" % repr(c))

  def error(self, mess):
    """Raise exception to signal syntax error in regexp."""
    raise RegexpSyntaxError("Syntax error in regexp %s at position %d: %s" % (
      repr(self.s), self.i, mess))



