# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# distutils language = c++

cimport c_async_waiter
cimport c_environment
cimport c_export  # needed so the init function gets exported
cimport c_thunks


from libc.stdint cimport uintptr_t


def SetSystemThunks(system_thunks_as_object):
  """Bind the basic Mojo Core functions.
  """
  cdef const c_thunks.MojoSystemThunks* system_thunks = (
      <const c_thunks.MojoSystemThunks*><uintptr_t>system_thunks_as_object)
  c_thunks.MojoSetSystemThunks(system_thunks)


cdef class RunLoop(object):
  """RunLoop to use when using asynchronous operations on handles."""

  cdef c_environment.CRunLoop* c_run_loop

  def __init__(self):
    assert not <uintptr_t>(c_environment.CRunLoopCurrent())
    self.c_run_loop = new c_environment.CRunLoop()

  def __dealloc__(self):
    del self.c_run_loop

  def Run(self):
    """Run the runloop until Quit is called."""
    self.c_run_loop.Run()

  def RunUntilIdle(self):
    """Run the runloop until Quit is called or no operation is waiting."""
    self.c_run_loop.RunUntilIdle()

  def Quit(self):
    """Quit the runloop."""
    self.c_run_loop.Quit()

  def PostDelayedTask(self, runnable, delay=0):
    """
    Post a task on the runloop. This must be called from the thread owning the
    runloop.
    """
    cdef c_environment.CClosure closure = c_environment.BuildClosure(runnable)
    self.c_run_loop.PostDelayedTask(closure, delay)


# We use a wrapping class to be able to call the C++ class PythonAsyncWaiter
# across module boundaries.
cdef class AsyncWaiter(object):
  cdef c_environment.CEnvironment* _cenvironment
  cdef c_async_waiter.PythonAsyncWaiter* _c_async_waiter

  def __init__(self):
    self._cenvironment = new c_environment.CEnvironment()
    self._c_async_waiter = c_environment.NewAsyncWaiter()

  def __dealloc__(self):
    del self._c_async_waiter
    del self._cenvironment

  def AsyncWait(self, handle, signals, deadline, callback):
    return self._c_async_waiter.AsyncWait(handle, signals, deadline, callback)

  def CancelWait(self, wait_id):
    self._c_async_waiter.CancelWait(wait_id)
