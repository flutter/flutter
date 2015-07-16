# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import random

import mojo_unittest
from mojo_bindings import promise

# pylint: disable=F0401
import mojo_system as system

# pylint: disable=F0401
from mojo_utils import data_pipe_utils


def _GetRandomBuffer(size):
  random.seed(size)
  return bytearray(''.join(chr(random.randint(0, 255)) for i in xrange(size)))


class DataPipeCopyTest(mojo_unittest.MojoTestCase):
  def setUp(self):
    super(DataPipeCopyTest, self).setUp()
    self.handles = system.DataPipe()
    self.error = None

  def tearDown(self):
    self.handles = None
    super(DataPipeCopyTest, self).tearDown()

  def _writeDataAndClose(self, handle, data):
    status, num_bytes_written = handle.WriteData(data)
    handle.Close()
    self.assertEquals(system.RESULT_OK, status)
    self.assertEquals(len(data), num_bytes_written)

  def _copyDataFromPipe(self, handle, expected_data,
                        deadline=system.DEADLINE_INDEFINITE):
    self._VerifyDataCopied(data_pipe_utils.CopyFromDataPipe(
         handle, deadline), expected_data).Catch(self._CatchError)

  def _CatchError(self, error):
    if self.loop:
      self.loop.Quit()
    self.error = error

  @promise.async
  def _VerifyDataCopied(self, data, expected_data):
    self.assertEquals(expected_data, data)
    self.loop.Quit()

  def _runAndCheckError(self):
    self.loop.Run()
    if self.error:
      # pylint: disable=E0702
      raise self.error

  def _testEagerWrite(self, data):
    self._writeDataAndClose(self.handles.producer_handle, data)
    self._copyDataFromPipe(self.handles.consumer_handle, data)
    self._runAndCheckError()

  def _testDelayedWrite(self, data):
    self._copyDataFromPipe(self.handles.consumer_handle, data)
    self._writeDataAndClose(self.handles.producer_handle, data)
    self._runAndCheckError()

  def testTimeout(self):
    self._copyDataFromPipe(self.handles.consumer_handle, bytearray(),
                           deadline=100)
    with self.assertRaises(data_pipe_utils.DataPipeCopyException):
      self._runAndCheckError()

  def testCloseProducerWithoutWriting(self):
    self._copyDataFromPipe(self.handles.consumer_handle, bytearray())
    self.handles.producer_handle.Close()
    self._runAndCheckError()

  def testEagerWriteOfEmptyData(self):
    self._testEagerWrite(bytearray())

  def testDelayedWriteOfEmptyData(self):
    self._testDelayedWrite(bytearray())

  def testEagerWriteOfNonEmptyData(self):
    self._testEagerWrite(_GetRandomBuffer(1024))

  def testDelayedWriteOfNonEmptyData(self):
    self._testDelayedWrite(_GetRandomBuffer(1024))

  def testEagerWriteOfLargeBuffer(self):
    self._testEagerWrite(_GetRandomBuffer(32 * 1024))

  def testDelayedWriteOfLargeBuffer(self):
    self._testDelayedWrite(_GetRandomBuffer(32 * 1024))
