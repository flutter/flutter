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
from mojom.generate import module as mojom


class ModuleTest(unittest.TestCase):

  def testNonInterfaceAsInterfaceRequest(self):
    """Tests that a non-interface cannot be used for interface requests."""
    module = mojom.Module('test_module', 'test_namespace')
    struct = mojom.Struct('TestStruct', module=module)
    with self.assertRaises(Exception) as e:
      mojom.InterfaceRequest(struct)
    self.assertEquals(
        e.exception.__str__(),
        'Interface request requires \'x:TestStruct\' to be an interface.')
