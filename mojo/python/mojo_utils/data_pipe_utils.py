# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import itertools
import sys

import mojo_system
from mojo_bindings import promise

class DataPipeCopyException(Exception):
  def __init__(self, *args, **kwargs):
    Exception.__init__(self, *args, **kwargs)
    self.__traceback__ = sys.exc_info()[2]


def CopyFromDataPipe(data_pipe, deadline):
  """
  Returns a Promise that operates as follows:
  - If |data_pipe| is successfully read from, the promise resolves with the
    bytes that were read.
  - Otherwise, the promise rejects with an exception whose message contains the
    status from the attempted read.
  """
  class DataPipeCopyHelper():
    def __init__(self, data_pipe, deadline, resolve, reject):
      self.data_pipe = data_pipe
      self.original_deadline = deadline
      self.start_time = mojo_system.GetTimeTicksNow()
      self.resolve = resolve
      self.reject = reject
      self.buffer_size = 1024
      self.data = bytearray(self.buffer_size)
      self.index = 0

    def _ComputeCurrentDeadline(self):
      if self.original_deadline == mojo_system.DEADLINE_INDEFINITE:
        return self.original_deadline
      elapsed_time = mojo_system.GetTimeTicksNow() - self.start_time
      return max(0, self.original_deadline - elapsed_time)

    def CopyFromDataPipeAsync(self, result):
      while result == mojo_system.RESULT_OK:
        assert self.index <= len(self.data)
        if self.index == len(self.data):
          self.buffer_size *= 2
          self.data.extend(itertools.repeat(0, self.buffer_size))

        # Careful! Have to construct a memoryview object here as otherwise the
        # slice operation will create a copy of |data| and hence not write into
        # |data| as desired.
        result, read_bytes = self.data_pipe.ReadData(
            memoryview(self.data)[self.index:])
        if read_bytes:
          self.index += len(read_bytes)
        del read_bytes

      if result == mojo_system.RESULT_SHOULD_WAIT:
        data_pipe.AsyncWait(mojo_system.HANDLE_SIGNAL_READABLE,
                            self._ComputeCurrentDeadline(),
                            self.CopyFromDataPipeAsync)
        return

      # Treat a failed precondition as EOF.
      if result == mojo_system.RESULT_FAILED_PRECONDITION:
        self.resolve(self.data[:self.index])
        return

      self.reject(DataPipeCopyException("Result: %d" % result))


  def GenerationMethod(resolve, reject):
    helper = DataPipeCopyHelper(data_pipe, deadline, resolve, reject)
    helper.CopyFromDataPipeAsync(mojo_system.RESULT_OK)

  return promise.Promise(GenerationMethod)
