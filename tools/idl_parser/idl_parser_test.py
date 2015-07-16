#!/usr/bin/env python
# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import glob
import unittest

from idl_lexer import IDLLexer
from idl_parser import IDLParser, ParseFile
from idl_ppapi_lexer import IDLPPAPILexer
from idl_ppapi_parser import IDLPPAPIParser

def ParseCommentTest(comment):
  comment = comment.strip()
  comments = comment.split(None, 1)
  return comments[0], comments[1]


class WebIDLParser(unittest.TestCase):
  def setUp(self):
    self.parser = IDLParser(IDLLexer(), mute_error=True)
    self.filenames = glob.glob('test_parser/*_web.idl')

  def _TestNode(self, node):
    comments = node.GetListOf('Comment')
    for comment in comments:
      check, value = ParseCommentTest(comment.GetName())
      if check == 'BUILD':
        msg = 'Expecting %s, but found %s.\n' % (value, str(node))
        self.assertEqual(value, str(node), msg)

      if check == 'ERROR':
        msg = node.GetLogLine('Expecting\n\t%s\nbut found \n\t%s\n' % (
                              value, str(node)))
        self.assertEqual(value, node.GetName(), msg)

      if check == 'PROP':
        key, expect = value.split('=')
        actual = str(node.GetProperty(key))
        msg = 'Mismatched property %s: %s vs %s.\n' % (key, expect, actual)
        self.assertEqual(expect, actual, msg)

      if check == 'TREE':
        quick = '\n'.join(node.Tree())
        lineno = node.GetProperty('LINENO')
        msg = 'Mismatched tree at line %d:\n%sVS\n%s' % (lineno, value, quick)
        self.assertEqual(value, quick, msg)

  def testExpectedNodes(self):
    for filename in self.filenames:
      filenode = ParseFile(self.parser, filename)
      children = filenode.GetChildren()
      self.assertTrue(len(children) > 2, 'Expecting children in %s.' %
                      filename)

      for node in filenode.GetChildren()[2:]:
        self._TestNode(node)


class PepperIDLParser(unittest.TestCase):
  def setUp(self):
    self.parser = IDLPPAPIParser(IDLPPAPILexer(), mute_error=True)
    self.filenames = glob.glob('test_parser/*_ppapi.idl')

  def _TestNode(self, filename, node):
    comments = node.GetListOf('Comment')
    for comment in comments:
      check, value = ParseCommentTest(comment.GetName())
      if check == 'BUILD':
        msg = '%s - Expecting %s, but found %s.\n' % (
            filename, value, str(node))
        self.assertEqual(value, str(node), msg)

      if check == 'ERROR':
        msg = node.GetLogLine('%s - Expecting\n\t%s\nbut found \n\t%s\n' % (
                              filename, value, str(node)))
        self.assertEqual(value, node.GetName(), msg)

      if check == 'PROP':
        key, expect = value.split('=')
        actual = str(node.GetProperty(key))
        msg = '%s - Mismatched property %s: %s vs %s.\n' % (
                              filename, key, expect, actual)
        self.assertEqual(expect, actual, msg)

      if check == 'TREE':
        quick = '\n'.join(node.Tree())
        lineno = node.GetProperty('LINENO')
        msg = '%s - Mismatched tree at line %d:\n%sVS\n%s' % (
                              filename, lineno, value, quick)
        self.assertEqual(value, quick, msg)

  def testExpectedNodes(self):
    for filename in self.filenames:
      filenode = ParseFile(self.parser, filename)
      children = filenode.GetChildren()
      self.assertTrue(len(children) > 2, 'Expecting children in %s.' %
                      filename)

      for node in filenode.GetChildren()[2:]:
        self._TestNode(filename, node)

if __name__ == '__main__':
  unittest.main(verbosity=2)

