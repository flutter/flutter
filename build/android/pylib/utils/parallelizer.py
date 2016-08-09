# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

""" Wrapper that allows method execution in parallel.

This class wraps a list of objects of the same type, emulates their
interface, and executes any functions called on the objects in parallel
in ReraiserThreads.

This means that, given a list of objects:

  class Foo:
    def __init__(self):
      self.baz = Baz()

    def bar(self, my_param):
      // do something

  list_of_foos = [Foo(1), Foo(2), Foo(3)]

we can take a sequential operation on that list of objects:

  for f in list_of_foos:
    f.bar('Hello')

and run it in parallel across all of the objects:

  Parallelizer(list_of_foos).bar('Hello')

It can also handle (non-method) attributes of objects, so that this:

  for f in list_of_foos:
    f.baz.myBazMethod()

can be run in parallel with:

  Parallelizer(list_of_foos).baz.myBazMethod()

Because it emulates the interface of the wrapped objects, a Parallelizer
can be passed to a method or function that takes objects of that type:

  def DoesSomethingWithFoo(the_foo):
    the_foo.bar('Hello')
    the_foo.bar('world')
    the_foo.baz.myBazMethod

  DoesSomethingWithFoo(Parallelizer(list_of_foos))

Note that this class spins up a thread for each object. Using this class
to parallelize operations that are already fast will incur a net performance
penalty.

"""
# pylint: disable=protected-access

from pylib.utils import reraiser_thread
from pylib.utils import watchdog_timer

_DEFAULT_TIMEOUT = 30
_DEFAULT_RETRIES = 3


class Parallelizer(object):
  """Allows parallel execution of method calls across a group of objects."""

  def __init__(self, objs):
    assert (objs is not None and len(objs) > 0), (
        "Passed empty list to 'Parallelizer'")
    self._orig_objs = objs
    self._objs = objs

  def __getattr__(self, name):
    """Emulate getting the |name| attribute of |self|.

    Args:
      name: The name of the attribute to retrieve.
    Returns:
      A Parallelizer emulating the |name| attribute of |self|.
    """
    self.pGet(None)

    r = type(self)(self._orig_objs)
    r._objs = [getattr(o, name) for o in self._objs]
    return r

  def __getitem__(self, index):
    """Emulate getting the value of |self| at |index|.

    Returns:
      A Parallelizer emulating the value of |self| at |index|.
    """
    self.pGet(None)

    r = type(self)(self._orig_objs)
    r._objs = [o[index] for o in self._objs]
    return r

  def __call__(self, *args, **kwargs):
    """Emulate calling |self| with |args| and |kwargs|.

    Note that this call is asynchronous. Call pFinish on the return value to
    block until the call finishes.

    Returns:
      A Parallelizer wrapping the ReraiserThreadGroup running the call in
      parallel.
    Raises:
      AttributeError if the wrapped objects aren't callable.
    """
    self.pGet(None)

    if not self._objs:
      raise AttributeError('Nothing to call.')
    for o in self._objs:
      if not callable(o):
        raise AttributeError("'%s' is not callable" % o.__name__)

    r = type(self)(self._orig_objs)
    r._objs = reraiser_thread.ReraiserThreadGroup(
        [reraiser_thread.ReraiserThread(
            o, args=args, kwargs=kwargs,
            name='%s.%s' % (str(d), o.__name__))
         for d, o in zip(self._orig_objs, self._objs)])
    r._objs.StartAll() # pylint: disable=W0212
    return r

  def pFinish(self, timeout):
    """Finish any outstanding asynchronous operations.

    Args:
      timeout: The maximum number of seconds to wait for an individual
               result to return, or None to wait forever.
    Returns:
      self, now emulating the return values.
    """
    self._assertNoShadow('pFinish')
    if isinstance(self._objs, reraiser_thread.ReraiserThreadGroup):
      self._objs.JoinAll()
      self._objs = self._objs.GetAllReturnValues(
          watchdog_timer.WatchdogTimer(timeout))
    return self

  def pGet(self, timeout):
    """Get the current wrapped objects.

    Args:
      timeout: Same as |pFinish|.
    Returns:
      A list of the results, in order of the provided devices.
    Raises:
      Any exception raised by any of the called functions.
    """
    self._assertNoShadow('pGet')
    self.pFinish(timeout)
    return self._objs

  def pMap(self, f, *args, **kwargs):
    """Map a function across the current wrapped objects in parallel.

    This calls f(o, *args, **kwargs) for each o in the set of wrapped objects.

    Note that this call is asynchronous. Call pFinish on the return value to
    block until the call finishes.

    Args:
      f: The function to call.
      args: The positional args to pass to f.
      kwargs: The keyword args to pass to f.
    Returns:
      A Parallelizer wrapping the ReraiserThreadGroup running the map in
      parallel.
    """
    self._assertNoShadow('pMap')
    r = type(self)(self._orig_objs)
    r._objs = reraiser_thread.ReraiserThreadGroup(
        [reraiser_thread.ReraiserThread(
            f, args=tuple([o] + list(args)), kwargs=kwargs,
            name='%s(%s)' % (f.__name__, d))
         for d, o in zip(self._orig_objs, self._objs)])
    r._objs.StartAll() # pylint: disable=W0212
    return r

  def _assertNoShadow(self, attr_name):
    """Ensures that |attr_name| isn't shadowing part of the wrapped obejcts.

    If the wrapped objects _do_ have an |attr_name| attribute, it will be
    inaccessible to clients.

    Args:
      attr_name: The attribute to check.
    Raises:
      AssertionError if the wrapped objects have an attribute named 'attr_name'
      or '_assertNoShadow'.
    """
    if isinstance(self._objs, reraiser_thread.ReraiserThreadGroup):
      assert not hasattr(self._objs, '_assertNoShadow')
      assert not hasattr(self._objs, attr_name)
    else:
      assert not any(hasattr(o, '_assertNoShadow') for o in self._objs)
      assert not any(hasattr(o, attr_name) for o in self._objs)


class SyncParallelizer(Parallelizer):
  """A Parallelizer that blocks on function calls."""

  #override
  def __call__(self, *args, **kwargs):
    """Emulate calling |self| with |args| and |kwargs|.

    Note that this call is synchronous.

    Returns:
      A Parallelizer emulating the value returned from calling |self| with
      |args| and |kwargs|.
    Raises:
      AttributeError if the wrapped objects aren't callable.
    """
    r = super(SyncParallelizer, self).__call__(*args, **kwargs)
    r.pFinish(None)
    return r

  #override
  def pMap(self, f, *args, **kwargs):
    """Map a function across the current wrapped objects in parallel.

    This calls f(o, *args, **kwargs) for each o in the set of wrapped objects.

    Note that this call is synchronous.

    Args:
      f: The function to call.
      args: The positional args to pass to f.
      kwargs: The keyword args to pass to f.
    Returns:
      A Parallelizer wrapping the ReraiserThreadGroup running the map in
      parallel.
    """
    r = super(SyncParallelizer, self).pMap(f, *args, **kwargs)
    r.pFinish(None)
    return r

