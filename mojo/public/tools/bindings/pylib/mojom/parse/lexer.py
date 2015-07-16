# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import imp
import os.path
import sys

def _GetDirAbove(dirname):
  """Returns the directory "above" this file containing |dirname| (which must
  also be "above" this file)."""
  path = os.path.abspath(__file__)
  while True:
    path, tail = os.path.split(path)
    assert tail
    if tail == dirname:
      return path

try:
  imp.find_module("ply")
except ImportError:
  sys.path.append(os.path.join(_GetDirAbove("public"), "public/third_party"))
from ply.lex import TOKEN

from ..error import Error


class LexError(Error):
  """Class for errors from the lexer."""

  def __init__(self, filename, message, lineno):
    Error.__init__(self, filename, message, lineno=lineno)


# We have methods which look like they could be functions:
# pylint: disable=R0201
class Lexer(object):

  def __init__(self, filename):
    self.filename = filename

  ######################--   PRIVATE   --######################

  ##
  ## Internal auxiliary methods
  ##
  def _error(self, msg, token):
    raise LexError(self.filename, msg, token.lineno)

  ##
  ## Reserved keywords
  ##
  keywords = (
    'HANDLE',

    'IMPORT',
    'MODULE',
    'STRUCT',
    'UNION',
    'INTERFACE',
    'ENUM',
    'CONST',
    'TRUE',
    'FALSE',
    'DEFAULT',
    'ARRAY',
    'MAP'
  )

  keyword_map = {}
  for keyword in keywords:
    keyword_map[keyword.lower()] = keyword

  ##
  ## All the tokens recognized by the lexer
  ##
  tokens = keywords + (
    # Identifiers
    'NAME',

    # Constants
    'ORDINAL',
    'INT_CONST_DEC', 'INT_CONST_HEX',
    'FLOAT_CONST',

    # String literals
    'STRING_LITERAL',

    # Operators
    'MINUS',
    'PLUS',
    'AMP',
    'QSTN',

    # Assignment
    'EQUALS',

    # Request / response
    'RESPONSE',

    # Delimiters
    'LPAREN', 'RPAREN',         # ( )
    'LBRACKET', 'RBRACKET',     # [ ]
    'LBRACE', 'RBRACE',         # { }
    'LANGLE', 'RANGLE',         # < >
    'SEMI',                     # ;
    'COMMA', 'DOT'              # , .
  )

  ##
  ## Regexes for use in tokens
  ##

  # valid C identifiers (K&R2: A.2.3)
  identifier = r'[a-zA-Z_][0-9a-zA-Z_]*'

  hex_prefix = '0[xX]'
  hex_digits = '[0-9a-fA-F]+'

  # integer constants (K&R2: A.2.5.1)
  decimal_constant = '0|([1-9][0-9]*)'
  hex_constant = hex_prefix+hex_digits
  # Don't allow octal constants (even invalid octal).
  octal_constant_disallowed = '0[0-9]+'

  # character constants (K&R2: A.2.5.2)
  # Note: a-zA-Z and '.-~^_!=&;,' are allowed as escape chars to support #line
  # directives with Windows paths as filenames (..\..\dir\file)
  # For the same reason, decimal_escape allows all digit sequences. We want to
  # parse all correct code, even if it means to sometimes parse incorrect
  # code.
  #
  simple_escape = r"""([a-zA-Z._~!=&\^\-\\?'"])"""
  decimal_escape = r"""(\d+)"""
  hex_escape = r"""(x[0-9a-fA-F]+)"""
  bad_escape = r"""([\\][^a-zA-Z._~^!=&\^\-\\?'"x0-7])"""

  escape_sequence = \
      r"""(\\("""+simple_escape+'|'+decimal_escape+'|'+hex_escape+'))'

  # string literals (K&R2: A.2.6)
  string_char = r"""([^"\\\n]|"""+escape_sequence+')'
  string_literal = '"'+string_char+'*"'
  bad_string_literal = '"'+string_char+'*'+bad_escape+string_char+'*"'

  # floating constants (K&R2: A.2.5.3)
  exponent_part = r"""([eE][-+]?[0-9]+)"""
  fractional_constant = r"""([0-9]*\.[0-9]+)|([0-9]+\.)"""
  floating_constant = \
      '(((('+fractional_constant+')'+ \
      exponent_part+'?)|([0-9]+'+exponent_part+')))'

  # Ordinals
  ordinal = r'@[0-9]+'
  missing_ordinal_value = r'@'
  # Don't allow ordinal values in octal (even invalid octal, like 09) or
  # hexadecimal.
  octal_or_hex_ordinal_disallowed = r'@((0[0-9]+)|('+hex_prefix+hex_digits+'))'

  ##
  ## Rules for the normal state
  ##
  t_ignore = ' \t\r'

  # Newlines
  def t_NEWLINE(self, t):
    r'\n+'
    t.lexer.lineno += len(t.value)

  # Operators
  t_MINUS             = r'-'
  t_PLUS              = r'\+'
  t_AMP               = r'&'
  t_QSTN              = r'\?'

  # =
  t_EQUALS            = r'='

  # =>
  t_RESPONSE          = r'=>'

  # Delimiters
  t_LPAREN            = r'\('
  t_RPAREN            = r'\)'
  t_LBRACKET          = r'\['
  t_RBRACKET          = r'\]'
  t_LBRACE            = r'\{'
  t_RBRACE            = r'\}'
  t_LANGLE            = r'<'
  t_RANGLE            = r'>'
  t_COMMA             = r','
  t_DOT               = r'\.'
  t_SEMI              = r';'

  t_STRING_LITERAL    = string_literal

  # The following floating and integer constants are defined as
  # functions to impose a strict order (otherwise, decimal
  # is placed before the others because its regex is longer,
  # and this is bad)
  #
  @TOKEN(floating_constant)
  def t_FLOAT_CONST(self, t):
    return t

  @TOKEN(hex_constant)
  def t_INT_CONST_HEX(self, t):
    return t

  @TOKEN(octal_constant_disallowed)
  def t_OCTAL_CONSTANT_DISALLOWED(self, t):
    msg = "Octal values not allowed"
    self._error(msg, t)

  @TOKEN(decimal_constant)
  def t_INT_CONST_DEC(self, t):
    return t

  # unmatched string literals are caught by the preprocessor

  @TOKEN(bad_string_literal)
  def t_BAD_STRING_LITERAL(self, t):
    msg = "String contains invalid escape code"
    self._error(msg, t)

  # Handle ordinal-related tokens in the right order:
  @TOKEN(octal_or_hex_ordinal_disallowed)
  def t_OCTAL_OR_HEX_ORDINAL_DISALLOWED(self, t):
    msg = "Octal and hexadecimal ordinal values not allowed"
    self._error(msg, t)

  @TOKEN(ordinal)
  def t_ORDINAL(self, t):
    return t

  @TOKEN(missing_ordinal_value)
  def t_BAD_ORDINAL(self, t):
    msg = "Missing ordinal value"
    self._error(msg, t)

  @TOKEN(identifier)
  def t_NAME(self, t):
    t.type = self.keyword_map.get(t.value, "NAME")
    return t

  # Ignore C and C++ style comments
  def t_COMMENT(self, t):
    r'(/\*(.|\n)*?\*/)|(//.*(\n[ \t]*//.*)*)'
    t.lexer.lineno += t.value.count("\n")

  def t_error(self, t):
    msg = "Illegal character %s" % repr(t.value[0])
    self._error(msg, t)
