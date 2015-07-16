# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# distutils language = c++

cimport c_core
cimport c_export  # needed so the init function gets exported
cimport c_thunks


from cpython.buffer cimport PyBUF_CONTIG
from cpython.buffer cimport PyBUF_CONTIG_RO
from cpython.buffer cimport Py_buffer
from cpython.buffer cimport PyBuffer_FillInfo
from cpython.buffer cimport PyBuffer_Release
from cpython.buffer cimport PyObject_GetBuffer
from cpython.mem cimport PyMem_Malloc, PyMem_Free
from cpython.object cimport Py_EQ, Py_NE
from libc.stdint cimport int32_t, int64_t, uint32_t, uint64_t, uintptr_t

import weakref
import threading

import mojo_system_impl

def SetSystemThunks(system_thunks_as_object):
  """Bind the basic Mojo Core functions.

  This should only be used by the embedder.
  """
  cdef const c_thunks.MojoSystemThunks* system_thunks = (
      <const c_thunks.MojoSystemThunks*><uintptr_t>system_thunks_as_object)
  c_thunks.MojoSetSystemThunks(system_thunks)

HANDLE_INVALID = c_core.MOJO_HANDLE_INVALID
RESULT_OK = c_core.MOJO_RESULT_OK
RESULT_CANCELLED = c_core.MOJO_RESULT_CANCELLED
RESULT_UNKNOWN = c_core.MOJO_RESULT_UNKNOWN
RESULT_INVALID_ARGUMENT = c_core.MOJO_RESULT_INVALID_ARGUMENT
RESULT_DEADLINE_EXCEEDED = c_core.MOJO_RESULT_DEADLINE_EXCEEDED
RESULT_NOT_FOUND = c_core.MOJO_RESULT_NOT_FOUND
RESULT_ALREADY_EXISTS = c_core.MOJO_RESULT_ALREADY_EXISTS
RESULT_PERMISSION_DENIED = c_core.MOJO_RESULT_PERMISSION_DENIED
RESULT_RESOURCE_EXHAUSTED = c_core.MOJO_RESULT_RESOURCE_EXHAUSTED
RESULT_FAILED_PRECONDITION = c_core.MOJO_RESULT_FAILED_PRECONDITION
RESULT_ABORTED = c_core.MOJO_RESULT_ABORTED
RESULT_OUT_OF_RANGE = c_core.MOJO_RESULT_OUT_OF_RANGE
RESULT_UNIMPLEMENTED = c_core.MOJO_RESULT_UNIMPLEMENTED
RESULT_INTERNAL = c_core.MOJO_RESULT_INTERNAL
RESULT_UNAVAILABLE = c_core.MOJO_RESULT_UNAVAILABLE
RESULT_DATA_LOSS = c_core.MOJO_RESULT_DATA_LOSS
RESULT_BUSY = c_core.MOJO_RESULT_BUSY
RESULT_SHOULD_WAIT = c_core.MOJO_RESULT_SHOULD_WAIT
DEADLINE_INDEFINITE = c_core.MOJO_DEADLINE_INDEFINITE
HANDLE_SIGNAL_NONE = c_core.MOJO_HANDLE_SIGNAL_NONE
HANDLE_SIGNAL_READABLE = c_core.MOJO_HANDLE_SIGNAL_READABLE
HANDLE_SIGNAL_WRITABLE = c_core.MOJO_HANDLE_SIGNAL_WRITABLE
HANDLE_SIGNAL_PEER_CLOSED = c_core.MOJO_HANDLE_SIGNAL_PEER_CLOSED
WRITE_MESSAGE_FLAG_NONE = c_core.MOJO_WRITE_MESSAGE_FLAG_NONE
READ_MESSAGE_FLAG_NONE = c_core.MOJO_READ_MESSAGE_FLAG_NONE
READ_MESSAGE_FLAG_MAY_DISCARD = c_core.MOJO_READ_MESSAGE_FLAG_MAY_DISCARD
WRITE_DATA_FLAG_NONE = c_core.MOJO_WRITE_DATA_FLAG_NONE
WRITE_DATA_FLAG_ALL_OR_NONE = c_core.MOJO_WRITE_DATA_FLAG_ALL_OR_NONE
READ_DATA_FLAG_NONE = c_core.MOJO_READ_DATA_FLAG_NONE
READ_DATA_FLAG_ALL_OR_NONE = c_core.MOJO_READ_DATA_FLAG_ALL_OR_NONE
READ_DATA_FLAG_DISCARD = c_core.MOJO_READ_DATA_FLAG_DISCARD
READ_DATA_FLAG_QUERY = c_core.MOJO_READ_DATA_FLAG_QUERY
READ_DATA_FLAG_PEEK = c_core.MOJO_READ_DATA_FLAG_PEEK
MAP_BUFFER_FLAG_NONE = c_core.MOJO_MAP_BUFFER_FLAG_NONE

_WAITMANY_NO_SIGNAL_STATE_ERRORS = [RESULT_INVALID_ARGUMENT,
                                    RESULT_RESOURCE_EXHAUSTED]

def GetTimeTicksNow():
  """Monotonically increasing tick count representing "right now."

  See mojo/public/c/system/functions.h
  """
  return c_core.MojoGetTimeTicksNow()

cdef class _ScopedMemory:
  """Allocate memory at creation, and deallocate it at destruction."""
  cdef void* memory
  def __init__(self, size):
    self.memory = PyMem_Malloc(size)

  def __dealloc__(self):
    PyMem_Free(self.memory)

cdef class _ScopedBuffer:
  """Retrieve pointer to a buffer a creation, and release it at destruction.
  """
  cdef Py_buffer _buf
  cdef void* buf
  cdef Py_ssize_t len

  def __init__(self, obj, flags=PyBUF_CONTIG_RO):
    if obj:
      if PyObject_GetBuffer(obj, &self._buf, flags) < 0:
        raise TypeError('Unable to read buffer.')
      self.buf = self._buf.buf
      self.len = self._buf.len
    else:
      self.buf = NULL
      self.len = 0

  def __dealloc__(self):
    if self.buf:
      PyBuffer_Release(&self._buf)

def _SliceBuffer(buffer, size):
  """Slice the given buffer, reducing it to the given size.

  Return None if None is passed in.
  """
  if not buffer:
    return buffer
  return buffer[:size]

cdef class _NativeMemoryView(object):
  """Create a python buffer wrapping the given memory.

  Will also retain the given handle until this object is deallocated.
  """
  cdef void* _memory
  cdef uint32_t _size
  cdef char _read_only
  cdef char _wrapped
  cdef object _handle

  def __init__(self, handle):
    self._handle = handle

  def __cinit__(self):
    self._memory = NULL
    self._size = 0
    self._read_only = True
    self._wrapped = False

  cdef Wrap(self,
            const void* memory,
            uint32_t size,
            read_only=True):
    """Makes this buffer wraps the given memory.

    Must be called before using this buffer, and must only be called once.
    """
    assert not self._wrapped
    self._wrapped = True
    self._memory = <void*>memory
    self._size = size
    self._read_only = read_only

  # buffer interface (PEP 3118)
  def __getbuffer__(self, Py_buffer *view, int flags):
    assert self._wrapped
    if view == NULL:
      return
    PyBuffer_FillInfo(view,
                      self,
                      self._memory,
                      self._size,
                      self._read_only,
                      flags)

  def __releasebuffer__(self, Py_buffer *view):
    assert self._wrapped
    pass

  # legacy buffer interface
  def __getsegcount__(self, Py_ssize_t *sizes):
    assert self._wrapped
    if sizes != NULL:
      sizes[0] = self._size
    return 1

  def __getreadbuffer__(self, Py_ssize_t index, void **data):
    assert self._wrapped
    if index != 0:
      raise SystemError('Index out of bounds: %d' % index)
    data[0] = self._memory
    return self._size

  def __getwritebuffer__(self, Py_ssize_t index, void **data):
    assert self._wrapped
    if index != 0:
      raise SystemError('Index out of bounds: %d' % index)
    if self._read_only:
      raise TypeError('Buffer is read-only.')
    data[0] = self._memory
    return self._size

class MojoException(Exception):
  """Exception wrapping a mojo result error code."""

  def __init__(self, mojo_result):
    self.mojo_result = mojo_result

def WaitMany(handles_and_signals, deadline):
  """Waits on a list of handles.

  Args:
    handles_and_signals: list of tuples of handle and signal.

  See mojo/public/c/system/functions.h
  """
  cdef uint32_t length = len(handles_and_signals)
  cdef uint32_t result_index = <uint32_t>(-1)

  cdef _ScopedMemory handles_alloc = _ScopedMemory(
      sizeof(c_core.MojoHandle) * length)
  cdef _ScopedMemory signals_alloc = _ScopedMemory(
      sizeof(c_core.MojoHandleSignals) * length)
  cdef _ScopedMemory states_alloc = _ScopedMemory(
      sizeof(c_core.MojoHandleSignalsState) * length)
  cdef c_core.MojoHandle* handles = <c_core.MojoHandle*>handles_alloc.memory
  cdef c_core.MojoHandleSignals* signals = (
      <c_core.MojoHandleSignals*>signals_alloc.memory)
  cdef c_core.MojoHandleSignalsState* states = (
      <c_core.MojoHandleSignalsState*>states_alloc.memory)
  cdef int index = 0
  for (h, s) in handles_and_signals:
    handles[index] = (<Handle?>h)._mojo_handle
    signals[index] = s
    index += 1
  cdef c_core.MojoResult result = c_core.MOJO_RESULT_OK
  cdef c_core.MojoDeadline cdeadline = deadline
  with nogil:
    result = c_core.MojoWaitMany(handles, signals, length, cdeadline,
                                 &result_index, states)

  returned_result_index = None
  if result_index != <uint32_t>(-1):
    returned_result_index = result_index

  returned_states = None
  if result not in _WAITMANY_NO_SIGNAL_STATE_ERRORS:
    returned_states = [(states[i].satisfied_signals,
                        states[i].satisfiable_signals) for i in xrange(length)]

  return (result, returned_result_index, returned_states)


cdef class DataPipeTwoPhaseBuffer(object):
  """Return value for two phases read and write.

  The buffer field contains the python buffer where data can be read or written.
  When done with the buffer, the |end| method must be called with the number of
  bytes read or written.
  """

  cdef object _buffer
  cdef Handle _handle
  cdef char _read

  def __init__(self, handle, buffer, read=True):
    self._buffer = buffer
    self._handle = handle
    self._read = read

  def End(self, num_bytes):
    self._buffer = None
    cdef c_core.MojoResult result
    if self._read:
      result = c_core.MojoEndReadData(self._handle._mojo_handle, num_bytes)
    else:
      result = c_core.MojoEndWriteData(self._handle._mojo_handle, num_bytes)
    self._handle = None
    return result

  @property
  def buffer(self):
    return self._buffer

  def __dealloc__(self):
    assert not self._buffer

cdef class MappedBuffer(object):
  """Return value for the |map| operation on shared buffer handles.

  The buffer field contains the python buffer where data can be read or written.
  When done with the buffer, the |unmap| method must be called.
  """

  cdef object _buffer
  cdef object _handle
  cdef object _cleanup

  def __init__(self, handle, buffer, cleanup):
    self._buffer = buffer
    self._handle = handle
    self._cleanup = cleanup

  def UnMap(self):
    self._buffer = None
    cdef c_core.MojoResult result = self._cleanup()
    self._cleanup = None
    self._handle = None
    return result

  @property
  def buffer(self):
    return self._buffer

  def __dealloc__(self):
    if self._buffer:
      self.UnMap()

cdef class Handle(object):
  """A mojo object."""

  cdef c_core.MojoHandle _mojo_handle

  def __init__(self, mojo_handle=c_core.MOJO_HANDLE_INVALID):
    self._mojo_handle = mojo_handle

  def _Invalidate(self):
    """Invalidate the current handle.

    The close operation is not called. It is the responsability of the caller to
    ensure that the handle is not leaked.
    """
    self._mojo_handle = c_core.MOJO_HANDLE_INVALID

  def __richcmp__(self, other, op):
    if op != Py_EQ and op != Py_NE:
      raise TypeError('Handle is not ordered')
    cdef int equality
    if type(self) is not type(other):
      equality = id(self) == id(other)
    else:
      equality = (<Handle>self)._mojo_handle == (<Handle>other)._mojo_handle
    if op == Py_EQ:
      return equality
    else:
      return not equality

  def IsValid(self):
    """Returns whether this handle is valid."""
    return self._mojo_handle != c_core.MOJO_HANDLE_INVALID

  def Close(self):
    """Closes this handle.

    See mojo/public/c/system/functions.h
    """
    cdef c_core.MojoResult result = c_core.MOJO_RESULT_OK
    if self.IsValid():
      result = c_core.MojoClose(self._mojo_handle)
      self._Invalidate()
    return result

  def __dealloc__(self):
    self.Close()

  def Wait(self, signals, deadline):
    """Waits on the given handle.

    See mojo/public/c/system/functions.h
    """
    cdef c_core.MojoHandle handle = self._mojo_handle
    cdef c_core.MojoHandleSignals csignals = signals
    cdef c_core.MojoDeadline cdeadline = deadline
    cdef c_core.MojoHandleSignalsState signal_states
    cdef c_core.MojoResult result
    with nogil:
      result = c_core.MojoWait(handle, csignals, cdeadline, &signal_states)

    returned_states = None
    if result not in _WAITMANY_NO_SIGNAL_STATE_ERRORS:
      returned_states = (signal_states.satisfied_signals,
            signal_states.satisfiable_signals)

    return (result, returned_states)

  def AsyncWait(self, signals, deadline, callback):
    cdef c_core.MojoHandle handle = self._mojo_handle
    cdef c_core.MojoHandleSignals csignals = signals
    cdef c_core.MojoDeadline cdeadline = deadline
    wait_id = _ASYNC_WAITER.AsyncWait(
        handle,
        csignals,
        cdeadline,
        callback)
    def cancel():
      _ASYNC_WAITER.CancelWait(wait_id)
    return cancel

  def WriteMessage(self,
                    buffer=None,
                    handles=None,
                    flags=WRITE_MESSAGE_FLAG_NONE):
    """Writes a message to the message pipe.

    This method can only be used on a handle obtained from |MessagePipe()|.

    See mojo/public/c/system/message_pipe.h
    """
    cdef _ScopedBuffer buffer_as_buffer = _ScopedBuffer(buffer)
    cdef uint32_t input_buffer_length = buffer_as_buffer.len
    cdef c_core.MojoHandle* input_handles = NULL
    cdef uint32_t input_handles_length = 0
    cdef _ScopedMemory handles_alloc = None
    if handles:
      input_handles_length = len(handles)
      handles_alloc = _ScopedMemory(sizeof(c_core.MojoHandle) *
                                    input_handles_length)
      input_handles = <c_core.MojoHandle*>handles_alloc.memory
      for i in xrange(input_handles_length):
        input_handles[i] = (<Handle?>handles[i])._mojo_handle
    cdef c_core.MojoResult res = c_core.MojoWriteMessage(self._mojo_handle,
                                                         buffer_as_buffer.buf,
                                                         input_buffer_length,
                                                         input_handles,
                                                         input_handles_length,
                                                         flags)
    if res == c_core.MOJO_RESULT_OK and handles:
      # Handles have been transferred. Let's invalidate those.
      for handle in handles:
        handle._Invalidate()
    return res

  def ReadMessage(self,
                   buffer=None,
                   max_number_of_handles=0,
                   flags=READ_MESSAGE_FLAG_NONE):
    """Reads a message from the message pipe.

    This method can only be used on a handle obtained from |MessagePipe()|.

    This method returns a triplet of value (code, data, sizes):
    - if code is RESULT_OK, sizes will be None, and data will be a pair of
      (buffer, handles) where buffer is a view of the input buffer with the read
      data, and handles is a list of received handles.
    - if code is RESULT_RESOURCE_EXHAUSTED, data will be None and sizes will be
      a pair of (buffer_size, handles_size) where buffer_size is the size of the
      next message data and handles_size is the number of handles in the next
      message.
    - if code is any other value, data and sizes will be None.

    See mojo/public/c/system/message_pipe.h
    """
    cdef _ScopedBuffer buffer_as_buffer = _ScopedBuffer(buffer, PyBUF_CONTIG)
    cdef uint32_t input_buffer_length = buffer_as_buffer.len
    cdef c_core.MojoHandle* input_handles = NULL
    cdef uint32_t input_handles_length = 0
    cdef _ScopedMemory handles_alloc = None
    if max_number_of_handles > 0:
      input_handles_length = max_number_of_handles
      handles_alloc = _ScopedMemory(sizeof(c_core.MojoHandle) *
                                    input_handles_length)
      input_handles = <c_core.MojoHandle*>handles_alloc.memory
    cdef res = c_core.MojoReadMessage(self._mojo_handle,
                                      buffer_as_buffer.buf,
                                      &input_buffer_length,
                                      input_handles,
                                      &input_handles_length,
                                      flags)
    if res == c_core.MOJO_RESULT_RESOURCE_EXHAUSTED:
      return (res, None, (input_buffer_length, input_handles_length))
    if res == c_core.MOJO_RESULT_OK:
      returned_handles = [Handle(input_handles[i])
                          for i in xrange(input_handles_length)]
      return (res,
              (_SliceBuffer(buffer, input_buffer_length), returned_handles),
              None)
    return (res, None, None)

  def WriteData(self, buffer=None, flags=WRITE_DATA_FLAG_NONE):
    """
    Writes the given data to the data pipe producer.

    This method can only be used on a producer handle obtained from
    |DataPipe()|.

    This method returns a tuple (code, num_bytes).
    - If code is RESULT_OK, num_bytes is the number of written bytes.
    - Otherwise, num_bytes is None.

    See mojo/public/c/system/data_pipe.h
    """
    cdef _ScopedBuffer buffer_as_buffer = _ScopedBuffer(buffer)
    cdef uint32_t input_buffer_length = buffer_as_buffer.len
    cdef c_core.MojoResult res = c_core.MojoWriteData(self._mojo_handle,
                                                      buffer_as_buffer.buf,
                                                      &input_buffer_length,
                                                      flags)
    if res == c_core.MOJO_RESULT_OK:
      return (res, input_buffer_length)
    return (res, None)

  def BeginWriteData(self,
                       min_size=None,
                       flags=WRITE_DATA_FLAG_NONE):
    """
    Begins a two-phase write to the data pipe producer.

    This method can only be used on a producer handle obtained from
    |DataPipe()|.

    This method returns a tuple (code, two_phase_buffer).
    - If code is RESULT_OK, two_phase_buffer is a writable
      DataPipeTwoPhaseBuffer
    - Otherwise, two_phase_buffer is None.

    See mojo/public/c/system/data_pipe.h
    """
    cdef void* out_buffer
    cdef uint32_t out_size = 0
    if min_size:
      flags |= c_core.MOJO_WRITE_DATA_FLAG_ALL_OR_NONE
      out_size = min_size
    cdef c_core.MojoResult res = c_core.MojoBeginWriteData(self._mojo_handle,
                                                           &out_buffer,
                                                           &out_size,
                                                           flags)
    if res != c_core.MOJO_RESULT_OK:
      return (res, None)
    cdef _NativeMemoryView view_buffer = _NativeMemoryView(self)
    view_buffer.Wrap(out_buffer, out_size, read_only=False)
    return (res, DataPipeTwoPhaseBuffer(self, memoryview(view_buffer), False))

  def ReadData(self, buffer=None, flags=READ_DATA_FLAG_NONE):
    """Reads data from the data pipe consumer.

    This method can only be used on a consumer handle obtained from
    |DataPipe()|.

    This method returns a tuple (code, buffer)
    - if code is RESULT_OK, buffer will be a view of the input buffer with the
      read data.
    - otherwise, buffer will be None.

    See mojo/public/c/system/data_pipe.h
    """
    cdef _ScopedBuffer buffer_as_buffer = _ScopedBuffer(buffer)
    cdef uint32_t input_buffer_length = buffer_as_buffer.len
    cdef c_core.MojoResult res = c_core.MojoReadData(self._mojo_handle,
                                                     buffer_as_buffer.buf,
                                                     &input_buffer_length,
                                                     flags)
    if res == c_core.MOJO_RESULT_OK:
      return (res, _SliceBuffer(buffer, input_buffer_length))
    return (res, None)

  def QueryData(self, flags=READ_DATA_FLAG_NONE):
    """Queries the amount of data available on the data pipe consumer.

    This method can only be used on a consumer handle obtained from
    |DataPipe()|.

    This method returns a tuple (code, num_bytes)
    - if code is RESULT_OK, num_bytes will be the number of bytes available on
      the data pipe consumer.
    - otherwise, num_bytes will be None.

    See mojo/public/c/system/data_pipe.h
    """
    cdef uint32_t num_bytes = 0
    cdef c_core.MojoResult res = c_core.MojoReadData(
        self._mojo_handle,
        NULL,
        &num_bytes,
        flags|c_core.MOJO_READ_DATA_FLAG_QUERY)
    return (res, num_bytes)

  def BeginReadData(self, min_size=None, flags=READ_DATA_FLAG_NONE):
    """
    Begins a two-phase read to the data pipe consumer.

    This method can only be used on a consumer handle obtained from
    |DataPipe()|.

    This method returns a tuple (code, two_phase_buffer).
    - If code is RESULT_OK, two_phase_buffer is a readable
      DataPipeTwoPhaseBuffer
    - Otherwise, two_phase_buffer is None.

    See mojo/public/c/system/data_pipe.h
    """
    cdef const void* out_buffer
    cdef uint32_t out_size = 0
    if min_size:
      flags |= c_core.MOJO_READ_DATA_FLAG_ALL_OR_NONE
      out_size = min_size
    cdef c_core.MojoResult res = c_core.MojoBeginReadData(self._mojo_handle,
                                                          &out_buffer,
                                                          &out_size,
                                                          flags)
    if res != c_core.MOJO_RESULT_OK:
      return (res, None)
    cdef _NativeMemoryView view_buffer = _NativeMemoryView(self)
    view_buffer.Wrap(out_buffer, out_size, read_only=True)
    return (res, DataPipeTwoPhaseBuffer(self, memoryview(view_buffer), True))

  def Duplicate(self, options=None):
    """Duplicate the shared buffer handle.

    This method can only be used on a handle obtained from
    |CreateSharedBuffer()| or |Duplicate()|.

    See mojo/public/c/system/buffer.h
    """
    cdef c_core.MojoDuplicateBufferHandleOptions coptions
    cdef c_core.MojoDuplicateBufferHandleOptions* coptions_ptr = NULL
    cdef c_core.MojoHandle cnew_handle = c_core.MOJO_HANDLE_INVALID
    if options:
      coptions.struct_size = sizeof(c_core.MojoDuplicateBufferHandleOptions)
      coptions.flags = options.flags
      coptions_ptr = &coptions
    cdef c_core.MojoResult result = c_core.MojoDuplicateBufferHandle(
        self._mojo_handle, coptions_ptr, &cnew_handle)
    new_handle = Handle(cnew_handle)
    if result != c_core.MOJO_RESULT_OK:
      raise MojoException(result)
    return new_handle

  def Map(self, offset, num_bytes, flags=MAP_BUFFER_FLAG_NONE):
    """Maps the part (at offset |offset| of length |num_bytes|) of the buffer.

    This method can only be used on a handle obtained from
    |CreateSharedBuffer()| or |Duplicate()|.

    This method returns a tuple (code, mapped_buffer).
    - If code is RESULT_OK, mapped_buffer is a readable/writable
      MappedBuffer
    - Otherwise, mapped_buffer is None.

    See mojo/public/c/system/buffer.h
    """
    cdef void* buffer
    res = c_core.MojoMapBuffer(self._mojo_handle,
                               offset,
                               num_bytes,
                               &buffer,
                               flags)
    if res != c_core.MOJO_RESULT_OK:
      return (res, None)
    cdef _NativeMemoryView view_buffer = _NativeMemoryView(self)
    view_buffer.Wrap(buffer, num_bytes, read_only=False)
    return (res, MappedBuffer(self,
                              memoryview(view_buffer),
                              lambda: c_core.MojoUnmapBuffer(buffer)))

class CreateMessagePipeOptions(object):
  """Options for creating a message pipe.

  See mojo/public/c/system/message_pipe.h
  """
  FLAG_NONE = c_core.MOJO_CREATE_MESSAGE_PIPE_OPTIONS_FLAG_NONE

  def __init__(self):
    self.flags = CreateMessagePipeOptions.FLAG_NONE

class MessagePipe(object):
  """Creates a message pipe.

  The two ends of the message pipe are accessible with the members handle0 and
  handle1.

  See mojo/public/c/system/message_pipe.h
  """
  def __init__(self, options=None):
    cdef c_core.MojoCreateMessagePipeOptions coptions
    cdef c_core.MojoCreateMessagePipeOptions* coptions_ptr = NULL
    cdef c_core.MojoHandle chandle0 = c_core.MOJO_HANDLE_INVALID
    cdef c_core.MojoHandle chandle1 = c_core.MOJO_HANDLE_INVALID
    if options:
      coptions.struct_size = sizeof(c_core.MojoCreateMessagePipeOptions)
      coptions.flags = options.flags
      coptions_ptr = &coptions
    cdef c_core.MojoResult result = c_core.MojoCreateMessagePipe(coptions_ptr,
                                                                 &chandle0,
                                                                 &chandle1)
    self.handle0 = Handle(chandle0)
    self.handle1 = Handle(chandle1)
    if result != c_core.MOJO_RESULT_OK:
      raise c_core.MojoException(result)


class CreateDataPipeOptions(object):
  """Options for creating a data pipe.

  See mojo/public/c/system/data_pipe.h
  """
  FLAG_NONE = c_core.MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE

  def __init__(self):
    self.flags = CreateDataPipeOptions.FLAG_NONE
    self.element_num_bytes = 1
    self.capacity_num_bytes = 0

class DataPipe(object):
  """Creates a data pipe.

  The producer end of the data pipe is accessible with the member
  producer_handle and the consumer end of the data pipe is accessible with the
  member cconsumer_handle.

  See mojo/public/c/system/data_pipe.h
  """
  def __init__(self, options=None):
    cdef c_core.MojoCreateDataPipeOptions coptions
    cdef c_core.MojoCreateDataPipeOptions* coptions_ptr = NULL
    cdef c_core.MojoHandle cproducer_handle = c_core.MOJO_HANDLE_INVALID
    cdef c_core.MojoHandle cconsumer_handle = c_core.MOJO_HANDLE_INVALID
    if options:
      coptions.struct_size = sizeof(c_core.MojoCreateDataPipeOptions)
      coptions.flags = options.flags
      coptions.element_num_bytes = options.element_num_bytes
      coptions.capacity_num_bytes = options.capacity_num_bytes
      coptions_ptr = &coptions
    cdef c_core.MojoResult result = c_core.MojoCreateDataPipe(coptions_ptr,
                                                              &cproducer_handle,
                                                              &cconsumer_handle)
    self.producer_handle = Handle(cproducer_handle)
    self.consumer_handle = Handle(cconsumer_handle)
    if result != c_core.MOJO_RESULT_OK:
      raise MojoException(result)

class CreateSharedBufferOptions(object):
  """Options for creating a shared buffer.

  See mojo/public/c/system/buffer.h
  """
  FLAG_NONE = c_core.MOJO_CREATE_SHARED_BUFFER_OPTIONS_FLAG_NONE

  def __init__(self):
    self.flags = CreateSharedBufferOptions.FLAG_NONE

def CreateSharedBuffer(num_bytes, options=None):
  """Creates a buffer of size |num_bytes| bytes that can be shared.

  See mojo/public/c/system/buffer.h
  """
  cdef c_core.MojoCreateSharedBufferOptions coptions
  cdef c_core.MojoCreateSharedBufferOptions* coptions_ptr = NULL
  cdef c_core.MojoHandle chandle = c_core.MOJO_HANDLE_INVALID
  if options:
    coptions.struct_size = sizeof(c_core.MojoCreateSharedBufferOptions)
    coptions.flags = options.flags
    coptions_ptr = &coptions
  cdef c_core.MojoResult result = c_core.MojoCreateSharedBuffer(coptions_ptr,
                                                                num_bytes,
                                                                &chandle)
  handle = Handle(chandle)
  if result != c_core.MOJO_RESULT_OK:
    raise MojoException(result)
  return handle

class DuplicateSharedBufferOptions(object):
  """Options for duplicating a shared buffer.

  See mojo/public/c/system/buffer.h
  """
  FLAG_NONE = c_core.MOJO_DUPLICATE_BUFFER_HANDLE_OPTIONS_FLAG_NONE

  def __init__(self):
    self.flags = DuplicateSharedBufferOptions.FLAG_NONE


# Keeps a thread local weak reference to the current run loop.
_RUN_LOOPS = threading.local()


class RunLoop(object):
  """RunLoop to use when using asynchronous operations on handles."""

  def __init__(self):
    self.__run_loop = mojo_system_impl.RunLoop()
    _RUN_LOOPS.loop = weakref.ref(self)

  def __del__(self):
    del _RUN_LOOPS.loop

  def Run(self):
    """Run the runloop until Quit is called."""
    return self.__run_loop.Run()

  def RunUntilIdle(self):
    """Run the runloop until Quit is called or no operation is waiting."""
    return self.__run_loop.RunUntilIdle()

  def Quit(self):
    """Quit the runloop."""
    return self.__run_loop.Quit()

  def PostDelayedTask(self, runnable, delay=0):
    """
    Post a task on the runloop. This must be called from the thread owning the
    runloop.
    """
    return self.__run_loop.PostDelayedTask(runnable, delay)

  @staticmethod
  def Current():
    if hasattr(_RUN_LOOPS, 'loop'):
      return _RUN_LOOPS.loop()
    return None


_ASYNC_WAITER = mojo_system_impl.AsyncWaiter()
