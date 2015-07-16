# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import unittest

# pylint: disable=E0611,F0401
import mojo_embedder
import mojo_system


class MojoTestCase(unittest.TestCase):
  def __init__(self, *args, **kwargs):
    unittest.TestCase.__init__(self, *args, **kwargs)
    self.loop = None

  def run(self, *args, **kwargs):
    try:
      mojo_embedder.Init()
      self.loop = mojo_system.RunLoop()
      unittest.TestCase.run(self, *args, **kwargs)
    finally:
      self.loop = None
      assert mojo_embedder.ShutdownForTest()
