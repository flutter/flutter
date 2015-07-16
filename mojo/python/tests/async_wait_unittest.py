# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import mojo_unittest

# pylint: disable=E0611
import mojo_system as system


class AsyncWaitTest(mojo_unittest.MojoTestCase):

  def setUp(self):
    super(AsyncWaitTest, self).setUp()
    self.array = []
    self.handles = system.MessagePipe()
    self.cancel = self.handles.handle0.AsyncWait(system.HANDLE_SIGNAL_READABLE,
                                                 system.DEADLINE_INDEFINITE,
                                                 self._OnResult)

  def tearDown(self):
    self.cancel()
    self.handles = None
    self.array = None
    super(AsyncWaitTest, self).tearDown()

  def _OnResult(self, value):
    self.array.append(value)

  def _WriteToHandle(self):
    self.handles.handle1.WriteMessage()

  def _PostWriteAndRun(self):
    self.loop.PostDelayedTask(self._WriteToHandle, 0)
    self.loop.RunUntilIdle()

  def testAsyncWait(self):
    self._PostWriteAndRun()
    self.assertEquals(len(self.array), 1)
    self.assertEquals(system.RESULT_OK, self.array[0])

  def testAsyncWaitCancel(self):
    self.loop.PostDelayedTask(self.cancel, 0)
    self._PostWriteAndRun()
    self.assertEquals(len(self.array), 0)

  def testAsyncWaitImmediateCancel(self):
    self.cancel()
    self._PostWriteAndRun()
    self.assertEquals(len(self.array), 0)
