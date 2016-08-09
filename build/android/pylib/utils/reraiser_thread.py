# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Thread and ThreadGroup that reraise exceptions on the main thread."""
# pylint: disable=W0212

import logging
import sys
import threading
import traceback

from pylib.utils import watchdog_timer


class TimeoutError(Exception):
  """Module-specific timeout exception."""
  pass


def LogThreadStack(thread):
  """Log the stack for the given thread.

  Args:
    thread: a threading.Thread instance.
  """
  stack = sys._current_frames()[thread.ident]
  logging.critical('*' * 80)
  logging.critical('Stack dump for thread %r', thread.name)
  logging.critical('*' * 80)
  for filename, lineno, name, line in traceback.extract_stack(stack):
    logging.critical('File: "%s", line %d, in %s', filename, lineno, name)
    if line:
      logging.critical('  %s', line.strip())
  logging.critical('*' * 80)


class ReraiserThread(threading.Thread):
  """Thread class that can reraise exceptions."""

  def __init__(self, func, args=None, kwargs=None, name=None):
    """Initialize thread.

    Args:
      func: callable to call on a new thread.
      args: list of positional arguments for callable, defaults to empty.
      kwargs: dictionary of keyword arguments for callable, defaults to empty.
      name: thread name, defaults to Thread-N.
    """
    super(ReraiserThread, self).__init__(name=name)
    if not args:
      args = []
    if not kwargs:
      kwargs = {}
    self.daemon = True
    self._func = func
    self._args = args
    self._kwargs = kwargs
    self._ret = None
    self._exc_info = None

  def ReraiseIfException(self):
    """Reraise exception if an exception was raised in the thread."""
    if self._exc_info:
      raise self._exc_info[0], self._exc_info[1], self._exc_info[2]

  def GetReturnValue(self):
    """Reraise exception if present, otherwise get the return value."""
    self.ReraiseIfException()
    return self._ret

  #override
  def run(self):
    """Overrides Thread.run() to add support for reraising exceptions."""
    try:
      self._ret = self._func(*self._args, **self._kwargs)
    except: # pylint: disable=W0702
      self._exc_info = sys.exc_info()


class ReraiserThreadGroup(object):
  """A group of ReraiserThread objects."""

  def __init__(self, threads=None):
    """Initialize thread group.

    Args:
      threads: a list of ReraiserThread objects; defaults to empty.
    """
    if not threads:
      threads = []
    self._threads = threads

  def Add(self, thread):
    """Add a thread to the group.

    Args:
      thread: a ReraiserThread object.
    """
    self._threads.append(thread)

  def StartAll(self):
    """Start all threads."""
    for thread in self._threads:
      thread.start()

  def _JoinAll(self, watcher=None):
    """Join all threads without stack dumps.

    Reraises exceptions raised by the child threads and supports breaking
    immediately on exceptions raised on the main thread.

    Args:
      watcher: Watchdog object providing timeout, by default waits forever.
    """
    if watcher is None:
      watcher = watchdog_timer.WatchdogTimer(None)
    alive_threads = self._threads[:]
    while alive_threads:
      for thread in alive_threads[:]:
        if watcher.IsTimedOut():
          raise TimeoutError('Timed out waiting for %d of %d threads.' %
                             (len(alive_threads), len(self._threads)))
        # Allow the main thread to periodically check for interrupts.
        thread.join(0.1)
        if not thread.isAlive():
          alive_threads.remove(thread)
    # All threads are allowed to complete before reraising exceptions.
    for thread in self._threads:
      thread.ReraiseIfException()

  def JoinAll(self, watcher=None):
    """Join all threads.

    Reraises exceptions raised by the child threads and supports breaking
    immediately on exceptions raised on the main thread. Unfinished threads'
    stacks will be logged on watchdog timeout.

    Args:
      watcher: Watchdog object providing timeout, by default waits forever.
    """
    try:
      self._JoinAll(watcher)
    except TimeoutError:
      for thread in (t for t in self._threads if t.isAlive()):
        LogThreadStack(thread)
      raise

  def GetAllReturnValues(self, watcher=None):
    """Get all return values, joining all threads if necessary.

    Args:
      watcher: same as in |JoinAll|. Only used if threads are alive.
    """
    if any([t.isAlive() for t in self._threads]):
      self.JoinAll(watcher)
    return [t.GetReturnValue() for t in self._threads]

