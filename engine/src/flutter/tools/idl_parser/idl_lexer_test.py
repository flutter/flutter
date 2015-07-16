#!/usr/bin/env python
# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import unittest

from idl_lexer import IDLLexer
from idl_ppapi_lexer import IDLPPAPILexer

#
# FileToTokens
#
# From a source file generate a list of tokens.
#
def FileToTokens(lexer, filename):
  with open(filename, 'rb') as srcfile:
    lexer.Tokenize(srcfile.read(), filename)
    return lexer.GetTokens()


#
# TextToTokens
#
# From a source file generate a list of tokens.
#
def TextToTokens(lexer, text):
  lexer.Tokenize(text)
  return lexer.GetTokens()


class WebIDLLexer(unittest.TestCase):
  def setUp(self):
    self.lexer = IDLLexer()
    self.filenames = [
        'test_lexer/values.in',
        'test_lexer/keywords.in'
    ]

  #
  # testRebuildText
  #
  # From a set of tokens, generate a new source text by joining with a
  # single space.  The new source is then tokenized and compared against the
  # old set.
  #
  def testRebuildText(self):
    for filename in self.filenames:
      tokens1 = FileToTokens(self.lexer, filename)
      to_text = '\n'.join(['%s' % t.value for t in tokens1])
      tokens2 = TextToTokens(self.lexer, to_text)

      count1 = len(tokens1)
      count2 = len(tokens2)
      self.assertEqual(count1, count2)

      for i in range(count1):
        msg = 'Value %s does not match original %s on line %d of %s.' % (
              tokens2[i].value, tokens1[i].value, tokens1[i].lineno, filename)
        self.assertEqual(tokens1[i].value, tokens2[i].value, msg)

  #
  # testExpectedType
  #
  # From a set of tokens pairs, verify the type field of the second matches
  # the value of the first, so that:
  # integer 123 float 1.1 ...
  # will generate a passing test, when the first token has both the type and
  # value of the keyword integer and the second has the type of integer and
  # value of 123 and so on.
  #
  def testExpectedType(self):
    for filename in self.filenames:
      tokens = FileToTokens(self.lexer, filename)
      count = len(tokens)
      self.assertTrue(count > 0)
      self.assertFalse(count & 1)

      index = 0
      while index < count:
        expect_type = tokens[index].value
        actual_type = tokens[index + 1].type
        msg = 'Type %s does not match expected %s on line %d of %s.' % (
              actual_type, expect_type, tokens[index].lineno, filename)
        index += 2
        self.assertEqual(expect_type, actual_type, msg)


class PepperIDLLexer(WebIDLLexer):
  def setUp(self):
    self.lexer = IDLPPAPILexer()
    self.filenames = [
        'test_lexer/values_ppapi.in',
        'test_lexer/keywords_ppapi.in'
    ]


if __name__ == '__main__':
  unittest.main()
