# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# distutils: language = c++

from libc.stdint cimport intptr_t, uint32_t, uint64_t


cdef extern from "mojo/public/c/system/core.h" nogil:
  ctypedef uint32_t MojoHandle
  ctypedef uint64_t MojoDeadline
  ctypedef uint32_t MojoHandleSignals


cdef extern from "mojo/public/c/environment/async_waiter.h"  nogil:
  ctypedef intptr_t MojoAsyncWaitID


cdef extern from "mojo/public/python/src/common.h" \
    namespace "mojo::python" nogil:
  cdef cppclass PythonAsyncWaiter "mojo::python::PythonAsyncWaiter":
    PythonAsyncWaiter()
    MojoAsyncWaitID AsyncWait(MojoHandle,
                              MojoHandleSignals,
                              MojoDeadline,
                              object)
    void CancelWait(MojoAsyncWaitID)
