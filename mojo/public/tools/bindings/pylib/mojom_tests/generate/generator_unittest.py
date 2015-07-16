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
from mojom.generate import generator


class StringManipulationTest(unittest.TestCase):
  """generator contains some string utilities, this tests only those."""

  def testUnderToCamel(self):
    """Tests UnderToCamel which converts underscore_separated to CamelCase."""
    self.assertEquals("CamelCase", generator.UnderToCamel("camel_case"))
    self.assertEquals("CamelCase", generator.UnderToCamel("CAMEL_CASE"))

if __name__ == "__main__":
  unittest.main()

