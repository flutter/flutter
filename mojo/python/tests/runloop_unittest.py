# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import mojo_unittest

# pylint: disable=E0611
import mojo_system as system


def _Increment(array):
  def _Closure():
    array.append(0)
  return _Closure


class RunLoopTest(mojo_unittest.MojoTestCase):

  def testRunLoop(self):
    array = []
    for _ in xrange(10):
      self.loop.PostDelayedTask(_Increment(array))
    self.loop.RunUntilIdle()
    self.assertEquals(len(array), 10)

  def testRunLoopWithException(self):
    def Throw():
      raise Exception("error")
    array = []
    self.loop.PostDelayedTask(Throw)
    self.loop.PostDelayedTask(_Increment(array))
    with self.assertRaisesRegexp(Exception, '^error$'):
      self.loop.Run()
    self.assertEquals(len(array), 0)
    self.loop.RunUntilIdle()
    self.assertEquals(len(array), 1)

  def testCurrent(self):
    self.assertEquals(system.RunLoop.Current(), self.loop)
    self.loop = None
    self.assertIsNone(system.RunLoop.Current())
