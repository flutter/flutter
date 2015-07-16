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
  imp.find_module("mojom")
except ImportError:
  sys.path.append(os.path.join(_GetDirAbove("pylib"), "pylib"))
import mojom.parse.ast as ast


class _TestNode(ast.NodeBase):
  """Node type for tests."""

  def __init__(self, value, **kwargs):
    super(_TestNode, self).__init__(**kwargs)
    self.value = value

  def __eq__(self, other):
    return super(_TestNode, self).__eq__(other) and self.value == other.value


class _TestNodeList(ast.NodeListBase):
  """Node list type for tests."""

  _list_item_type = _TestNode


class ASTTest(unittest.TestCase):
  """Tests various AST classes."""

  def testNodeBase(self):
    # Test |__eq__()|; this is only used for testing, where we want to do
    # comparison by value and ignore filenames/line numbers (for convenience).
    node1 = ast.NodeBase(filename="hello.mojom", lineno=123)
    node2 = ast.NodeBase()
    self.assertEquals(node1, node2)
    self.assertEquals(node2, node1)

    # Check that |__ne__()| just defers to |__eq__()| properly.
    self.assertFalse(node1 != node2)
    self.assertFalse(node2 != node1)

    # Check that |filename| and |lineno| are set properly (and are None by
    # default).
    self.assertEquals(node1.filename, "hello.mojom")
    self.assertEquals(node1.lineno, 123)
    self.assertIsNone(node2.filename)
    self.assertIsNone(node2.lineno)

    # |NodeBase|'s |__eq__()| should compare types (and a subclass's |__eq__()|
    # should first defer to its superclass's).
    node3 = _TestNode(123)
    self.assertNotEqual(node1, node3)
    self.assertNotEqual(node3, node1)
    # Also test |__eq__()| directly.
    self.assertFalse(node1 == node3)
    self.assertFalse(node3 == node1)

    node4 = _TestNode(123, filename="world.mojom", lineno=123)
    self.assertEquals(node4, node3)
    node5 = _TestNode(456)
    self.assertNotEquals(node5, node4)

  def testNodeListBase(self):
    node1 = _TestNode(1, filename="foo.mojom", lineno=1)
    # Equal to, but not the same as, |node1|:
    node1b = _TestNode(1, filename="foo.mojom", lineno=1)
    node2 = _TestNode(2, filename="foo.mojom", lineno=2)

    nodelist1 = _TestNodeList()  # Contains: (empty).
    self.assertEquals(nodelist1, nodelist1)
    self.assertEquals(nodelist1.items, [])
    self.assertIsNone(nodelist1.filename)
    self.assertIsNone(nodelist1.lineno)

    nodelist2 = _TestNodeList(node1)  # Contains: 1.
    self.assertEquals(nodelist2, nodelist2)
    self.assertEquals(nodelist2.items, [node1])
    self.assertNotEqual(nodelist2, nodelist1)
    self.assertEquals(nodelist2.filename, "foo.mojom")
    self.assertEquals(nodelist2.lineno, 1)

    nodelist3 = _TestNodeList([node2])  # Contains: 2.
    self.assertEquals(nodelist3.items, [node2])
    self.assertNotEqual(nodelist3, nodelist1)
    self.assertNotEqual(nodelist3, nodelist2)
    self.assertEquals(nodelist3.filename, "foo.mojom")
    self.assertEquals(nodelist3.lineno, 2)

    nodelist1.Append(node1b)  # Contains: 1.
    self.assertEquals(nodelist1.items, [node1])
    self.assertEquals(nodelist1, nodelist2)
    self.assertNotEqual(nodelist1, nodelist3)
    self.assertEquals(nodelist1.filename, "foo.mojom")
    self.assertEquals(nodelist1.lineno, 1)

    nodelist1.Append(node2)  # Contains: 1, 2.
    self.assertEquals(nodelist1.items, [node1, node2])
    self.assertNotEqual(nodelist1, nodelist2)
    self.assertNotEqual(nodelist1, nodelist3)
    self.assertEquals(nodelist1.lineno, 1)

    nodelist2.Append(node2)  # Contains: 1, 2.
    self.assertEquals(nodelist2.items, [node1, node2])
    self.assertEquals(nodelist2, nodelist1)
    self.assertNotEqual(nodelist2, nodelist3)
    self.assertEquals(nodelist2.lineno, 1)

    nodelist3.Insert(node1)  # Contains: 1, 2.
    self.assertEquals(nodelist3.items, [node1, node2])
    self.assertEquals(nodelist3, nodelist1)
    self.assertEquals(nodelist3, nodelist2)
    self.assertEquals(nodelist3.lineno, 1)

    # Test iteration:
    i = 1
    for item in nodelist1:
      self.assertEquals(item.value, i)
      i += 1
