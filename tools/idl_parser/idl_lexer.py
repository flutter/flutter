#!/usr/bin/env python
# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

""" Lexer for PPAPI IDL

The lexer uses the PLY library to build a tokenizer which understands both
WebIDL and Pepper tokens.

WebIDL, and WebIDL regular expressions can be found at:
   http://www.w3.org/TR/2012/CR-WebIDL-20120419/
PLY can be found at:
   http://www.dabeaz.com/ply/
"""

import os.path
import sys

#
# Try to load the ply module, if not, then assume it is in the third_party
# directory.
#
try:
  # Disable lint check which fails to find the ply module.
  # pylint: disable=F0401
  from ply import lex
except ImportError:
  module_path, module_name = os.path.split(__file__)
  third_party = os.path.join(module_path, '..', '..', 'third_party')
  sys.path.append(third_party)
  # pylint: disable=F0401
  from ply import lex

#
# IDL Lexer
#
class IDLLexer(object):
  # 'literals' is a value expected by lex which specifies a list of valid
  # literal tokens, meaning the token type and token value are identical.
  literals = r'"*.(){}[],;:=+-/~|&^?<>'

  # 't_ignore' contains ignored characters (spaces and tabs)
  t_ignore = ' \t'

  # 'tokens' is a value required by lex which specifies the complete list
  # of valid token types.
  tokens = [
    # Data types
      'float',
      'integer',
      'string',

    # Symbol and keywords types
      'COMMENT',
      'identifier',

    # MultiChar operators
      'ELLIPSIS',
  ]

  # 'keywords' is a map of string to token type.  All tokens matching
  # KEYWORD_OR_SYMBOL are matched against keywords dictionary, to determine
  # if the token is actually a keyword.
  keywords = {
    'any' : 'ANY',
    'attribute' : 'ATTRIBUTE',
    'boolean' : 'BOOLEAN',
    'byte' : 'BYTE',
    'ByteString' : 'BYTESTRING',
    'callback' : 'CALLBACK',
    'const' : 'CONST',
    'creator' : 'CREATOR',
    'Date' : 'DATE',
    'deleter' : 'DELETER',
    'dictionary' : 'DICTIONARY',
    'DOMString' : 'DOMSTRING',
    'double' : 'DOUBLE',
    'enum'  : 'ENUM',
    'exception' : 'EXCEPTION',
    'false' : 'FALSE',
    'float' : 'FLOAT',
    'getter': 'GETTER',
    'implements' : 'IMPLEMENTS',
    'Infinity' : 'INFINITY',
    'inherit' : 'INHERIT',
    'interface' : 'INTERFACE',
    'iterable': 'ITERABLE',
    'legacycaller' : 'LEGACYCALLER',
    'legacyiterable' : 'LEGACYITERABLE',
    'long' : 'LONG',
    'maplike': 'MAPLIKE',
    'Nan' : 'NAN',
    'null' : 'NULL',
    'object' : 'OBJECT',
    'octet' : 'OCTET',
    'optional' : 'OPTIONAL',
    'or' : 'OR',
    'partial' : 'PARTIAL',
    'Promise' : 'PROMISE',
    'readonly' : 'READONLY',
    'RegExp' : 'REGEXP',
    'required' : 'REQUIRED',
    'sequence' : 'SEQUENCE',
    'serializer' : 'SERIALIZER',
    'setlike' : 'SETLIKE',
    'setter': 'SETTER',
    'short' : 'SHORT',
    'static' : 'STATIC',
    'stringifier' : 'STRINGIFIER',
    'typedef' : 'TYPEDEF',
    'true' : 'TRUE',
    'unsigned' : 'UNSIGNED',
    'unrestricted' : 'UNRESTRICTED',
    'void' : 'VOID'
  }

  # Token definitions
  #
  # Lex assumes any value or function in the form of 't_<TYPE>' represents a
  # regular expression where a match will emit a token of type <TYPE>.  In the
  # case of a function, the function is called when a match is made. These
  # definitions come from WebIDL.
  #
  # These need to be methods for lexer construction, despite not using self.
  # pylint: disable=R0201
  def t_ELLIPSIS(self, t):
    r'\.\.\.'
    return t

  # Regex needs to be in the docstring
  # pylint: disable=C0301
  def t_float(self, t):
    r'-?(([0-9]+\.[0-9]*|[0-9]*\.[0-9]+)([Ee][+-]?[0-9]+)?|[0-9]+[Ee][+-]?[0-9]+)'
    return t

  def t_integer(self, t):
    r'-?([1-9][0-9]*|0[Xx][0-9A-Fa-f]+|0[0-7]*)'
    return t


  # A line ending '\n', we use this to increment the line number
  def t_LINE_END(self, t):
    r'\n+'
    self.AddLines(len(t.value))

  # We do not process escapes in the IDL strings.  Strings are exclusively
  # used for attributes and enums, and not used as typical 'C' constants.
  def t_string(self, t):
    r'"[^"]*"'
    t.value = t.value[1:-1]
    self.AddLines(t.value.count('\n'))
    return t

  # A C or C++ style comment:  /* xxx */ or //
  def t_COMMENT(self, t):
    r'(/\*(.|\n)*?\*/)|(//.*(\n[ \t]*//.*)*)'
    self.AddLines(t.value.count('\n'))
    return t

  # A symbol or keyword.
  def t_KEYWORD_OR_SYMBOL(self, t):
    r'_?[A-Za-z][A-Za-z_0-9]*'

    # All non-keywords are assumed to be symbols
    t.type = self.keywords.get(t.value, 'identifier')

    # We strip leading underscores so that you can specify symbols with the same
    # value as a keywords (E.g. a dictionary named 'interface').
    if t.value[0] == '_':
      t.value = t.value[1:]
    return t

  def t_ANY_error(self, t):
    msg = 'Unrecognized input'
    line = self.Lexer().lineno

    # If that line has not been accounted for, then we must have hit
    # EoF, so compute the beginning of the line that caused the problem.
    if line >= len(self.index):
      # Find the offset in the line of the first word causing the issue
      word = t.value.split()[0]
      offs = self.lines[line - 1].find(word)
      # Add the computed line's starting position
      self.index.append(self.Lexer().lexpos - offs)
      msg = 'Unexpected EoF reached after'

    pos = self.Lexer().lexpos - self.index[line]
    out = self.ErrorMessage(line, pos, msg)
    sys.stderr.write(out + '\n')
    self._lex_errors += 1


  def AddLines(self, count):
    # Set the lexer position for the beginning of the next line.  In the case
    # of multiple lines, tokens can not exist on any of the lines except the
    # last one, so the recorded value for previous lines are unused.  We still
    # fill the array however, to make sure the line count is correct.
    self.Lexer().lineno += count
    for _ in range(count):
      self.index.append(self.Lexer().lexpos)

  def FileLineMsg(self, line, msg):
    # Generate a message containing the file and line number of a token.
    filename = self.Lexer().filename
    if filename:
      return "%s(%d) : %s" % (filename, line + 1, msg)
    return "<BuiltIn> : %s" % msg

  def SourceLine(self, line, pos):
    # Create a source line marker
    caret = ' ' * pos + '^'
    # We decrement the line number since the array is 0 based while the
    # line numbers are 1 based.
    return "%s\n%s" % (self.lines[line - 1], caret)

  def ErrorMessage(self, line, pos, msg):
    return "\n%s\n%s" % (
        self.FileLineMsg(line, msg),
        self.SourceLine(line, pos))

#
# Tokenizer
#
# The token function returns the next token provided by IDLLexer for matching
# against the leaf paterns.
#
  def token(self):
    tok = self.Lexer().token()
    if tok:
      self.last = tok
    return tok


  def GetTokens(self):
    outlist = []
    while True:
      t = self.Lexer().token()
      if not t:
        break
      outlist.append(t)
    return outlist

  def Tokenize(self, data, filename='__no_file__'):
    lexer = self.Lexer()
    lexer.lineno = 1
    lexer.filename = filename
    lexer.input(data)
    self.lines = data.split('\n')

  def KnownTokens(self):
    return self.tokens

  def Lexer(self):
    if not self._lexobj:
      self._lexobj = lex.lex(object=self, lextab=None, optimize=0)
    return self._lexobj

  def _AddToken(self, token):
    if token in self.tokens:
      raise RuntimeError('Same token: ' + token)
    self.tokens.append(token)

  def _AddTokens(self, tokens):
    for token in tokens:
      self._AddToken(token)

  def _AddKeywords(self, keywords):
    for key in keywords:
      value = key.upper()
      self._AddToken(value)
      self.keywords[key] = value

  def _DelKeywords(self, keywords):
    for key in keywords:
      self.tokens.remove(key.upper())
      del self.keywords[key]

  def __init__(self):
    self.index = [0]
    self._lex_errors = 0
    self.linex = []
    self.filename = None
    self.keywords = {}
    self.tokens = []
    self._AddTokens(IDLLexer.tokens)
    self._AddKeywords(IDLLexer.keywords)
    self._lexobj = None
    self.last = None
    self.lines = None

# If run by itself, attempt to build the lexer
if __name__ == '__main__':
  lexer_object = IDLLexer()
