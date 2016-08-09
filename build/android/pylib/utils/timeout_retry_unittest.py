# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Unittests for timeout_and_retry.py."""

import unittest

from pylib.utils import reraiser_thread
from pylib.utils import timeout_retry


class TestException(Exception):
  pass


def _NeverEnding(tries):
  tries[0] += 1
  while True:
    pass


def _CountTries(tries):
  tries[0] += 1
  raise TestException


class TestRun(unittest.TestCase):
  """Tests for timeout_retry.Run."""

  def testRun(self):
    self.assertTrue(timeout_retry.Run(
        lambda x: x, 30, 3, [True], {}))

  def testTimeout(self):
    tries = [0]
    self.assertRaises(reraiser_thread.TimeoutError,
        timeout_retry.Run, lambda: _NeverEnding(tries), 0, 3)
    self.assertEqual(tries[0], 4)

  def testRetries(self):
    tries = [0]
    self.assertRaises(TestException,
        timeout_retry.Run, lambda: _CountTries(tries), 30, 3)
    self.assertEqual(tries[0], 4)

  def testReturnValue(self):
    self.assertTrue(timeout_retry.Run(lambda: True, 30, 3))


if __name__ == '__main__':
  unittest.main()
