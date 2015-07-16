# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import random
import time

import mojo_unittest

# pylint: disable=E0611
import mojo_system as system

DATA_SIZE = 1024


def _GetRandomBuffer(size):
  random.seed(size)
  return bytearray(''.join(chr(random.randint(0, 255)) for i in xrange(size)))


class CoreTest(mojo_unittest.MojoTestCase):

  HANDLE_SIGNAL_READWRITABLE = (system.HANDLE_SIGNAL_READABLE |
      system.HANDLE_SIGNAL_WRITABLE)
  HANDLE_SIGNAL_ALL = (system.HANDLE_SIGNAL_READABLE |
      system.HANDLE_SIGNAL_WRITABLE | system.HANDLE_SIGNAL_PEER_CLOSED)

  def testResults(self):
    self.assertEquals(system.RESULT_OK, 0)
    self.assertGreater(system.RESULT_CANCELLED, 0)
    self.assertGreater(system.RESULT_UNKNOWN, 0)
    self.assertGreater(system.RESULT_INVALID_ARGUMENT, 0)
    self.assertGreater(system.RESULT_DEADLINE_EXCEEDED, 0)
    self.assertGreater(system.RESULT_NOT_FOUND, 0)
    self.assertGreater(system.RESULT_ALREADY_EXISTS, 0)
    self.assertGreater(system.RESULT_PERMISSION_DENIED, 0)
    self.assertGreater(system.RESULT_RESOURCE_EXHAUSTED, 0)
    self.assertGreater(system.RESULT_FAILED_PRECONDITION, 0)
    self.assertGreater(system.RESULT_ABORTED, 0)
    self.assertGreater(system.RESULT_OUT_OF_RANGE, 0)
    self.assertGreater(system.RESULT_UNIMPLEMENTED, 0)
    self.assertGreater(system.RESULT_INTERNAL, 0)
    self.assertGreater(system.RESULT_UNAVAILABLE, 0)
    self.assertGreater(system.RESULT_DATA_LOSS, 0)
    self.assertGreater(system.RESULT_BUSY, 0)
    self.assertGreater(system.RESULT_SHOULD_WAIT, 0)

  def testConstants(self):
    self.assertGreaterEqual(system.DEADLINE_INDEFINITE, 0)
    self.assertGreaterEqual(system.HANDLE_SIGNAL_NONE, 0)
    self.assertGreaterEqual(system.HANDLE_SIGNAL_READABLE, 0)
    self.assertGreaterEqual(system.HANDLE_SIGNAL_WRITABLE, 0)
    self.assertGreaterEqual(system.HANDLE_SIGNAL_PEER_CLOSED, 0)
    self.assertGreaterEqual(system.WRITE_MESSAGE_FLAG_NONE, 0)
    self.assertGreaterEqual(system.READ_MESSAGE_FLAG_NONE, 0)
    self.assertGreaterEqual(system.READ_MESSAGE_FLAG_MAY_DISCARD, 0)
    self.assertGreaterEqual(system.WRITE_DATA_FLAG_NONE, 0)
    self.assertGreaterEqual(system.WRITE_DATA_FLAG_ALL_OR_NONE, 0)
    self.assertGreaterEqual(system.READ_DATA_FLAG_NONE, 0)
    self.assertGreaterEqual(system.READ_DATA_FLAG_ALL_OR_NONE, 0)
    self.assertGreaterEqual(system.READ_DATA_FLAG_DISCARD, 0)
    self.assertGreaterEqual(system.READ_DATA_FLAG_QUERY, 0)
    self.assertGreaterEqual(system.READ_DATA_FLAG_PEEK, 0)
    self.assertGreaterEqual(system.MAP_BUFFER_FLAG_NONE, 0)

  def testGetTimeTicksNow(self):
    v1 = system.GetTimeTicksNow()
    time.sleep(1e-3)
    v2 = system.GetTimeTicksNow()
    self.assertGreater(v1, 0)
    self.assertGreater(v2, v1 + 1e2)
    self.assertLess(v2, v1 + 1e5)

  def _testHandlesCreation(self, *args):
    for handle in args:
      self.assertTrue(handle.IsValid())
      handle.Close()
      self.assertFalse(handle.IsValid())

  def _TestMessageHandleCreation(self, handles):
    self._testHandlesCreation(handles.handle0, handles.handle1)

  def testCreateMessagePipe(self):
    self._TestMessageHandleCreation(system.MessagePipe())

  def testCreateMessagePipeWithNoneOptions(self):
    self._TestMessageHandleCreation(system.MessagePipe(None))

  def testCreateMessagePipeWithOptions(self):
    self._TestMessageHandleCreation(
        system.MessagePipe(system.CreateMessagePipeOptions()))

  def testWaitOverMessagePipe(self):
    handles = system.MessagePipe()
    handle = handles.handle0

    (res, states) = handle.Wait(
        system.HANDLE_SIGNAL_WRITABLE, system.DEADLINE_INDEFINITE)
    self.assertEquals(system.RESULT_OK, res)
    self.assertEquals(system.HANDLE_SIGNAL_WRITABLE, states[0])
    self.assertEquals(CoreTest.HANDLE_SIGNAL_ALL, states[1])

    (res, states) = handle.Wait(system.HANDLE_SIGNAL_READABLE, 0)
    self.assertEquals(system.RESULT_DEADLINE_EXCEEDED, res)
    self.assertEquals(system.HANDLE_SIGNAL_WRITABLE, states[0])
    self.assertEquals(CoreTest.HANDLE_SIGNAL_ALL, states[1])

    handles.handle1.WriteMessage()

    (res, states) = handle.Wait(
            system.HANDLE_SIGNAL_READABLE,
            system.DEADLINE_INDEFINITE)
    self.assertEquals(system.RESULT_OK, res)
    self.assertEquals(CoreTest.HANDLE_SIGNAL_READWRITABLE, states[0])
    self.assertEquals(CoreTest.HANDLE_SIGNAL_ALL, states[1])

  def testWaitInvalidArgument(self):
    (res, index, states) = system.WaitMany(
            [(system.Handle(0), system.HANDLE_SIGNAL_WRITABLE),
             (system.Handle(0), system.HANDLE_SIGNAL_WRITABLE)],
            system.DEADLINE_INDEFINITE)
    self.assertEquals(system.RESULT_INVALID_ARGUMENT, res)
    self.assertEquals(0, index)
    self.assertEquals(states, None)

  def testWaitOverManyMessagePipe(self):
    handles = system.MessagePipe()
    handle0 = handles.handle0
    handle1 = handles.handle1

    (res, index, states) = system.WaitMany(
            [(handle0, system.HANDLE_SIGNAL_WRITABLE),
             (handle1, system.HANDLE_SIGNAL_WRITABLE)],
            system.DEADLINE_INDEFINITE)
    self.assertEquals(system.RESULT_OK, res)
    self.assertEquals(0, index)
    self.assertEquals(system.HANDLE_SIGNAL_WRITABLE, states[0][0])
    self.assertEquals(CoreTest.HANDLE_SIGNAL_ALL, states[0][1])
    self.assertEquals(system.HANDLE_SIGNAL_WRITABLE, states[1][0])
    self.assertEquals(CoreTest.HANDLE_SIGNAL_ALL, states[1][1])

    (res, index, states) = system.WaitMany(
            [(handle0, system.HANDLE_SIGNAL_READABLE),
             (handle1, system.HANDLE_SIGNAL_READABLE)], 0)
    self.assertEquals(system.RESULT_DEADLINE_EXCEEDED, res)
    self.assertEquals(None, index)
    self.assertEquals(system.HANDLE_SIGNAL_WRITABLE, states[0][0])
    self.assertEquals(CoreTest.HANDLE_SIGNAL_ALL, states[0][1])
    self.assertEquals(system.HANDLE_SIGNAL_WRITABLE, states[1][0])
    self.assertEquals(CoreTest.HANDLE_SIGNAL_ALL, states[1][1])

    handle0.WriteMessage()

    (res, index, states) = system.WaitMany(
            [(handle0, system.HANDLE_SIGNAL_READABLE),
             (handle1, system.HANDLE_SIGNAL_READABLE)],
            system.DEADLINE_INDEFINITE)
    self.assertEquals(system.RESULT_OK, res)
    self.assertEquals(1, index)
    self.assertEquals(system.HANDLE_SIGNAL_WRITABLE, states[0][0])
    self.assertEquals(CoreTest.HANDLE_SIGNAL_ALL, states[0][1])
    self.assertEquals(CoreTest.HANDLE_SIGNAL_READWRITABLE, states[1][0])
    self.assertEquals(CoreTest.HANDLE_SIGNAL_ALL, states[1][1])

  def testSendBytesOverMessagePipe(self):
    handles = system.MessagePipe()
    data = _GetRandomBuffer(DATA_SIZE)
    handles.handle0.WriteMessage(data)
    (res, buffers, next_message) = handles.handle1.ReadMessage()
    self.assertEquals(system.RESULT_RESOURCE_EXHAUSTED, res)
    self.assertEquals(None, buffers)
    self.assertEquals((DATA_SIZE, 0), next_message)
    result = bytearray(DATA_SIZE)
    (res, buffers, next_message) = handles.handle1.ReadMessage(result)
    self.assertEquals(system.RESULT_OK, res)
    self.assertEquals(None, next_message)
    self.assertEquals((data, []), buffers)

  def testSendEmptyDataOverMessagePipe(self):
    handles = system.MessagePipe()
    handles.handle0.WriteMessage(None)
    (res, buffers, next_message) = handles.handle1.ReadMessage()

    self.assertEquals(system.RESULT_OK, res)
    self.assertEquals(None, next_message)
    self.assertEquals((None, []), buffers)

  def testSendHandleOverMessagePipe(self):
    handles = system.MessagePipe()
    handles_to_send = system.MessagePipe()
    handles.handle0.WriteMessage(handles=[handles_to_send.handle0,
                                           handles_to_send.handle1])
    (res, buffers, next_message) = handles.handle1.ReadMessage(
        max_number_of_handles=2)

    self.assertFalse(handles_to_send.handle0.IsValid())
    self.assertFalse(handles_to_send.handle1.IsValid())
    self.assertEquals(system.RESULT_OK, res)
    self.assertEquals(None, next_message)
    self.assertEquals(None, buffers[0])
    self.assertEquals(2, len(buffers[1]))

    handles = buffers[1]
    for handle in handles:
      self.assertTrue(handle.IsValid())
      (res, buffers, next_message) = handle.ReadMessage()
      self.assertEquals(system.RESULT_SHOULD_WAIT, res)

    for handle in handles:
      handle.WriteMessage()

    for handle in handles:
      (res, buffers, next_message) = handle.ReadMessage()
      self.assertEquals(system.RESULT_OK, res)

  def _TestDataHandleCreation(self, handles):
    self._testHandlesCreation(
        handles.producer_handle, handles.consumer_handle)

  def testCreateDataPipe(self):
    self._TestDataHandleCreation(system.DataPipe())

  def testCreateDataPipeWithNoneOptions(self):
    self._TestDataHandleCreation(system.DataPipe(None))

  def testCreateDataPipeWithDefaultOptions(self):
    self._TestDataHandleCreation(
        system.DataPipe(system.CreateDataPipeOptions()))

  def testCreateDataPipeWithElementSize(self):
    options = system.CreateDataPipeOptions()
    options.element_num_bytes = 5
    self._TestDataHandleCreation(system.DataPipe(options))

  def testCreateDataPipeWithCapacity(self):
    options = system.CreateDataPipeOptions()
    options.element_capacity_num_bytes = DATA_SIZE
    self._TestDataHandleCreation(system.DataPipe(options))

  def testCreateDataPipeWithIncorrectParameters(self):
    options = system.CreateDataPipeOptions()
    options.element_num_bytes = 5
    options.capacity_num_bytes = DATA_SIZE
    with self.assertRaises(system.MojoException) as cm:
      self._TestDataHandleCreation(system.DataPipe(options))
    self.assertEquals(system.RESULT_INVALID_ARGUMENT, cm.exception.mojo_result)

  def testSendEmptyDataOverDataPipe(self):
    pipes = system.DataPipe()
    self.assertEquals((system.RESULT_OK, 0), pipes.producer_handle.WriteData())
    self.assertEquals(
        (system.RESULT_OK, None), pipes.consumer_handle.ReadData())

  def testSendDataOverDataPipe(self):
    pipes = system.DataPipe()
    data = _GetRandomBuffer(DATA_SIZE)
    self.assertEquals((system.RESULT_OK, DATA_SIZE),
                      pipes.producer_handle.WriteData(data))
    self.assertEquals((system.RESULT_OK, data),
                      pipes.consumer_handle.ReadData(
                          bytearray(DATA_SIZE), system.READ_DATA_FLAG_PEEK))
    self.assertEquals((system.RESULT_OK, data),
                      pipes.consumer_handle.ReadData(bytearray(DATA_SIZE)))

  def testTwoPhaseWriteOnDataPipe(self):
    pipes = system.DataPipe()
    (res, buf) = pipes.producer_handle.BeginWriteData(DATA_SIZE)
    self.assertEquals(system.RESULT_OK, res)
    self.assertGreaterEqual(len(buf.buffer), DATA_SIZE)
    data = _GetRandomBuffer(DATA_SIZE)
    buf.buffer[0:DATA_SIZE] = data
    self.assertEquals(system.RESULT_OK, buf.End(DATA_SIZE))
    self.assertEquals((system.RESULT_OK, data),
                      pipes.consumer_handle.ReadData(bytearray(DATA_SIZE)))

  def testTwoPhaseReadOnDataPipe(self):
    pipes = system.DataPipe()
    data = _GetRandomBuffer(DATA_SIZE)
    self.assertEquals((system.RESULT_OK, DATA_SIZE),
                      pipes.producer_handle.WriteData(data))
    (res, buf) = pipes.consumer_handle.BeginReadData()
    self.assertEquals(system.RESULT_OK, res)
    self.assertEquals(DATA_SIZE, len(buf.buffer))
    self.assertEquals(data, buf.buffer)
    self.assertEquals(system.RESULT_OK, buf.End(DATA_SIZE))

  def testCreateSharedBuffer(self):
    self._testHandlesCreation(system.CreateSharedBuffer(DATA_SIZE))

  def testCreateSharedBufferWithNoneOptions(self):
    self._testHandlesCreation(system.CreateSharedBuffer(DATA_SIZE, None))

  def testCreateSharedBufferWithDefaultOptions(self):
    self._testHandlesCreation(
        system.CreateSharedBuffer(
            DATA_SIZE,
            system.CreateSharedBufferOptions()))

  def testDuplicateSharedBuffer(self):
    handle = system.CreateSharedBuffer(DATA_SIZE)
    self._testHandlesCreation(handle.Duplicate())

  def testDuplicateSharedBufferWithNoneOptions(self):
    handle = system.CreateSharedBuffer(DATA_SIZE)
    self._testHandlesCreation(handle.Duplicate(None))

  def testDuplicateSharedBufferWithDefaultOptions(self):
    handle = system.CreateSharedBuffer(DATA_SIZE)
    self._testHandlesCreation(
        handle.Duplicate(system.DuplicateSharedBufferOptions()))

  def testSendBytesOverSharedBuffer(self):
    handle = system.CreateSharedBuffer(DATA_SIZE)
    duplicated = handle.Duplicate()
    data = _GetRandomBuffer(DATA_SIZE)
    (res1, buf1) = handle.Map(0, DATA_SIZE)
    (res2, buf2) = duplicated.Map(0, DATA_SIZE)
    self.assertEquals(system.RESULT_OK, res1)
    self.assertEquals(system.RESULT_OK, res2)
    self.assertEquals(DATA_SIZE, len(buf1.buffer))
    self.assertEquals(DATA_SIZE, len(buf2.buffer))
    self.assertEquals(buf1.buffer, buf2.buffer)

    buf1.buffer[:] = data
    self.assertEquals(data, buf1.buffer)
    self.assertEquals(data, buf2.buffer)
    self.assertEquals(buf1.buffer, buf2.buffer)
