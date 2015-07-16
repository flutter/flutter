# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# distutils: language = c++

from libc.stdint cimport int64_t, intptr_t, uint32_t, uint64_t

cimport c_async_waiter


cdef extern from "mojo/public/cpp/bindings/callback.h" nogil:
  cdef cppclass CClosure "mojo::Callback<void()>":
    CClosure()


cdef extern from "mojo/public/python/src/python_system_helper.h" \
    namespace "mojo::python" nogil:
  cdef CClosure BuildClosure(object)
  cdef c_async_waiter.PythonAsyncWaiter* NewAsyncWaiter()


cdef extern from "mojo/public/cpp/utility/run_loop.h" nogil:
  cdef cppclass CRunLoop "mojo::RunLoop":
    CRunLoop()
    void Run() except *
    void RunUntilIdle() except *
    void Quit()
    void PostDelayedTask(CClosure&, int64_t)
  cdef CRunLoop CRunLoopCurrent "mojo::RunLoop::current"()


cdef extern from "mojo/public/cpp/environment/environment.h" nogil:
  cdef cppclass CEnvironment "mojo::Environment":
    CEnvironment()
