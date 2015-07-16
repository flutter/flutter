# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import imp
import os.path
import sys
import unittest

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
from ply import lex

try:
  imp.find_module("mojom")
except ImportError:
  sys.path.append(os.path.join(_GetDirAbove("pylib"), "pylib"))
import mojom.parse.lexer


# This (monkey-patching LexToken to make comparison value-based) is evil, but
# we'll do it anyway. (I'm pretty sure ply's lexer never cares about comparing
# for object identity.)
def _LexTokenEq(self, other):
  return self.type == other.type and self.value == other.value and \
         self.lineno == other.lineno and self.lexpos == other.lexpos
setattr(lex.LexToken, '__eq__', _LexTokenEq)


def _MakeLexToken(token_type, value, lineno=1, lexpos=0):
  """Makes a LexToken with the given parameters. (Note that lineno is 1-based,
  but lexpos is 0-based.)"""
  rv = lex.LexToken()
  rv.type, rv.value, rv.lineno, rv.lexpos = token_type, value, lineno, lexpos
  return rv


def _MakeLexTokenForKeyword(keyword, **kwargs):
  """Makes a LexToken for the given keyword."""
  return _MakeLexToken(keyword.upper(), keyword.lower(), **kwargs)


class LexerTest(unittest.TestCase):
  """Tests |mojom.parse.lexer.Lexer|."""

  def __init__(self, *args, **kwargs):
    unittest.TestCase.__init__(self, *args, **kwargs)
    # Clone all lexer instances from this one, since making a lexer is slow.
    self._zygote_lexer = lex.lex(mojom.parse.lexer.Lexer("my_file.mojom"))

  def testValidKeywords(self):
    """Tests valid keywords."""
    self.assertEquals(self._SingleTokenForInput("handle"),
                      _MakeLexTokenForKeyword("handle"))
    self.assertEquals(self._SingleTokenForInput("import"),
                      _MakeLexTokenForKeyword("import"))
    self.assertEquals(self._SingleTokenForInput("module"),
                      _MakeLexTokenForKeyword("module"))
    self.assertEquals(self._SingleTokenForInput("struct"),
                      _MakeLexTokenForKeyword("struct"))
    self.assertEquals(self._SingleTokenForInput("union"),
                      _MakeLexTokenForKeyword("union"))
    self.assertEquals(self._SingleTokenForInput("interface"),
                      _MakeLexTokenForKeyword("interface"))
    self.assertEquals(self._SingleTokenForInput("enum"),
                      _MakeLexTokenForKeyword("enum"))
    self.assertEquals(self._SingleTokenForInput("const"),
                      _MakeLexTokenForKeyword("const"))
    self.assertEquals(self._SingleTokenForInput("true"),
                      _MakeLexTokenForKeyword("true"))
    self.assertEquals(self._SingleTokenForInput("false"),
                      _MakeLexTokenForKeyword("false"))
    self.assertEquals(self._SingleTokenForInput("default"),
                      _MakeLexTokenForKeyword("default"))
    self.assertEquals(self._SingleTokenForInput("array"),
                      _MakeLexTokenForKeyword("array"))
    self.assertEquals(self._SingleTokenForInput("map"),
                      _MakeLexTokenForKeyword("map"))

  def testValidIdentifiers(self):
    """Tests identifiers."""
    self.assertEquals(self._SingleTokenForInput("abcd"),
                      _MakeLexToken("NAME", "abcd"))
    self.assertEquals(self._SingleTokenForInput("AbC_d012_"),
                      _MakeLexToken("NAME", "AbC_d012_"))
    self.assertEquals(self._SingleTokenForInput("_0123"),
                      _MakeLexToken("NAME", "_0123"))

  def testInvalidIdentifiers(self):
    with self.assertRaisesRegexp(
        mojom.parse.lexer.LexError,
        r"^my_file\.mojom:1: Error: Illegal character '\$'$"):
      self._TokensForInput("$abc")
    with self.assertRaisesRegexp(
        mojom.parse.lexer.LexError,
        r"^my_file\.mojom:1: Error: Illegal character '\$'$"):
      self._TokensForInput("a$bc")

  def testDecimalIntegerConstants(self):
    self.assertEquals(self._SingleTokenForInput("0"),
                      _MakeLexToken("INT_CONST_DEC", "0"))
    self.assertEquals(self._SingleTokenForInput("1"),
                      _MakeLexToken("INT_CONST_DEC", "1"))
    self.assertEquals(self._SingleTokenForInput("123"),
                      _MakeLexToken("INT_CONST_DEC", "123"))
    self.assertEquals(self._SingleTokenForInput("10"),
                      _MakeLexToken("INT_CONST_DEC", "10"))

  def testValidTokens(self):
    """Tests valid tokens (which aren't tested elsewhere)."""
    # Keywords tested in |testValidKeywords|.
    # NAME tested in |testValidIdentifiers|.
    self.assertEquals(self._SingleTokenForInput("@123"),
                      _MakeLexToken("ORDINAL", "@123"))
    self.assertEquals(self._SingleTokenForInput("456"),
                      _MakeLexToken("INT_CONST_DEC", "456"))
    self.assertEquals(self._SingleTokenForInput("0x01aB2eF3"),
                      _MakeLexToken("INT_CONST_HEX", "0x01aB2eF3"))
    self.assertEquals(self._SingleTokenForInput("123.456"),
                      _MakeLexToken("FLOAT_CONST", "123.456"))
    self.assertEquals(self._SingleTokenForInput("\"hello\""),
                      _MakeLexToken("STRING_LITERAL", "\"hello\""))
    self.assertEquals(self._SingleTokenForInput("+"),
                      _MakeLexToken("PLUS", "+"))
    self.assertEquals(self._SingleTokenForInput("-"),
                      _MakeLexToken("MINUS", "-"))
    self.assertEquals(self._SingleTokenForInput("&"),
                      _MakeLexToken("AMP", "&"))
    self.assertEquals(self._SingleTokenForInput("?"),
                      _MakeLexToken("QSTN", "?"))
    self.assertEquals(self._SingleTokenForInput("="),
                      _MakeLexToken("EQUALS", "="))
    self.assertEquals(self._SingleTokenForInput("=>"),
                      _MakeLexToken("RESPONSE", "=>"))
    self.assertEquals(self._SingleTokenForInput("("),
                      _MakeLexToken("LPAREN", "("))
    self.assertEquals(self._SingleTokenForInput(")"),
                      _MakeLexToken("RPAREN", ")"))
    self.assertEquals(self._SingleTokenForInput("["),
                      _MakeLexToken("LBRACKET", "["))
    self.assertEquals(self._SingleTokenForInput("]"),
                      _MakeLexToken("RBRACKET", "]"))
    self.assertEquals(self._SingleTokenForInput("{"),
                      _MakeLexToken("LBRACE", "{"))
    self.assertEquals(self._SingleTokenForInput("}"),
                      _MakeLexToken("RBRACE", "}"))
    self.assertEquals(self._SingleTokenForInput("<"),
                      _MakeLexToken("LANGLE", "<"))
    self.assertEquals(self._SingleTokenForInput(">"),
                      _MakeLexToken("RANGLE", ">"))
    self.assertEquals(self._SingleTokenForInput(";"),
                      _MakeLexToken("SEMI", ";"))
    self.assertEquals(self._SingleTokenForInput(","),
                      _MakeLexToken("COMMA", ","))
    self.assertEquals(self._SingleTokenForInput("."),
                      _MakeLexToken("DOT", "."))

  def _TokensForInput(self, input_string):
    """Gets a list of tokens for the given input string."""
    lexer = self._zygote_lexer.clone()
    lexer.input(input_string)
    rv = []
    while True:
      tok = lexer.token()
      if not tok:
        return rv
      rv.append(tok)

  def _SingleTokenForInput(self, input_string):
    """Gets the single token for the given input string. (Raises an exception if
    the input string does not result in exactly one token.)"""
    toks = self._TokensForInput(input_string)
    assert len(toks) == 1
    return toks[0]


if __name__ == "__main__":
  unittest.main()
