# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import imp
import os.path
import shutil
import sys
import tempfile
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
from mojom import fileutil


class FileUtilTest(unittest.TestCase):

  def testEnsureDirectoryExists(self):
    """Test that EnsureDirectoryExists fuctions correctly."""

    temp_dir = tempfile.mkdtemp()
    try:
      self.assertTrue(os.path.exists(temp_dir))

      # Directory does not exist, yet.
      full = os.path.join(temp_dir, "foo", "bar")
      self.assertFalse(os.path.exists(full))

      # Create the directory.
      fileutil.EnsureDirectoryExists(full)
      self.assertTrue(os.path.exists(full))

      # Trying to create it again does not cause an error.
      fileutil.EnsureDirectoryExists(full)
      self.assertTrue(os.path.exists(full))

      # Bypass check for directory existence to tickle error handling that
      # occurs in response to a race.
      fileutil.EnsureDirectoryExists(full, always_try_to_create=True)
      self.assertTrue(os.path.exists(full))
    finally:
      shutil.rmtree(temp_dir)
