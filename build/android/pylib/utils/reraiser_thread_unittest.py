# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Unittests for reraiser_thread.py."""

import threading
import unittest

from pylib.utils import reraiser_thread
from pylib.utils import watchdog_timer


class TestException(Exception):
  pass


class TestReraiserThread(unittest.TestCase):
  """Tests for reraiser_thread.ReraiserThread."""
  def testNominal(self):
    result = [None, None]

    def f(a, b=None):
      result[0] = a
      result[1] = b

    thread = reraiser_thread.ReraiserThread(f, [1], {'b': 2})
    thread.start()
    thread.join()
    self.assertEqual(result[0], 1)
    self.assertEqual(result[1], 2)

  def testRaise(self):
    def f():
      raise TestException

    thread = reraiser_thread.ReraiserThread(f)
    thread.start()
    thread.join()
    with self.assertRaises(TestException):
      thread.ReraiseIfException()


class TestReraiserThreadGroup(unittest.TestCase):
  """Tests for reraiser_thread.ReraiserThreadGroup."""
  def testInit(self):
    ran = [False] * 5
    def f(i):
      ran[i] = True

    group = reraiser_thread.ReraiserThreadGroup(
      [reraiser_thread.ReraiserThread(f, args=[i]) for i in range(5)])
    group.StartAll()
    group.JoinAll()
    for v in ran:
      self.assertTrue(v)

  def testAdd(self):
    ran = [False] * 5
    def f(i):
      ran[i] = True

    group = reraiser_thread.ReraiserThreadGroup()
    for i in xrange(5):
      group.Add(reraiser_thread.ReraiserThread(f, args=[i]))
    group.StartAll()
    group.JoinAll()
    for v in ran:
      self.assertTrue(v)

  def testJoinRaise(self):
    def f():
      raise TestException
    group = reraiser_thread.ReraiserThreadGroup(
      [reraiser_thread.ReraiserThread(f) for _ in xrange(5)])
    group.StartAll()
    with self.assertRaises(TestException):
      group.JoinAll()

  def testJoinTimeout(self):
    def f():
      pass
    event = threading.Event()
    def g():
      event.wait()
    group = reraiser_thread.ReraiserThreadGroup(
        [reraiser_thread.ReraiserThread(g),
         reraiser_thread.ReraiserThread(f)])
    group.StartAll()
    with self.assertRaises(reraiser_thread.TimeoutError):
      group.JoinAll(watchdog_timer.WatchdogTimer(0.01))
    event.set()


if __name__ == '__main__':
  unittest.main()
