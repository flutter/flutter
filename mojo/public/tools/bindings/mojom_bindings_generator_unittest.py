# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import unittest

from mojom_bindings_generator import MakeImportStackMessage


class MojoBindingsGeneratorTest(unittest.TestCase):
  """Tests mojo_bindings_generator."""

  def testMakeImportStackMessage(self):
    """Tests MakeImportStackMessage()."""
    self.assertEquals(MakeImportStackMessage(["x"]), "")
    self.assertEquals(MakeImportStackMessage(["x", "y"]),
        "\n  y was imported by x")
    self.assertEquals(MakeImportStackMessage(["x", "y", "z"]),
        "\n  z was imported by y\n  y was imported by x")


if __name__ == "__main__":
  unittest.main()
