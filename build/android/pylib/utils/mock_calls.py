# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
A test facility to assert call sequences while mocking their behavior.
"""

import os
import sys
import unittest

from pylib import constants

sys.path.append(os.path.join(
    constants.DIR_SOURCE_ROOT, 'third_party', 'pymock'))
import mock # pylint: disable=F0401


class TestCase(unittest.TestCase):
  """Adds assertCalls to TestCase objects."""
  class _AssertCalls(object):
    def __init__(self, test_case, expected_calls, watched):
      def call_action(pair):
        if isinstance(pair, type(mock.call)):
          return (pair, None)
        else:
          return pair

      def do_check(call):
        def side_effect(*args, **kwargs):
          received_call = call(*args, **kwargs)
          self._test_case.assertTrue(
              self._expected_calls,
              msg=('Unexpected call: %s' % str(received_call)))
          expected_call, action = self._expected_calls.pop(0)
          self._test_case.assertTrue(
              received_call == expected_call,
              msg=('Expected call mismatch:\n'
                   '  expected: %s\n'
                   '  received: %s\n'
                   % (str(expected_call), str(received_call))))
          if callable(action):
            return action(*args, **kwargs)
          else:
            return action
        return side_effect

      self._test_case = test_case
      self._expected_calls = [call_action(pair) for pair in expected_calls]
      watched = watched.copy() # do not pollute the caller's dict
      watched.update((call.parent.name, call.parent)
                     for call, _ in self._expected_calls)
      self._patched = [test_case.patch_call(call, side_effect=do_check(call))
                       for call in watched.itervalues()]

    def __enter__(self):
      for patch in self._patched:
        patch.__enter__()
      return self

    def __exit__(self, exc_type, exc_val, exc_tb):
      for patch in self._patched:
        patch.__exit__(exc_type, exc_val, exc_tb)
      if exc_type is None:
        missing = ''.join('  expected: %s\n' % str(call)
                          for call, _ in self._expected_calls)
        self._test_case.assertFalse(
            missing,
            msg='Expected calls not found:\n' + missing)

  def __init__(self, *args, **kwargs):
    super(TestCase, self).__init__(*args, **kwargs)
    self.call = mock.call.self
    self._watched = {}

  def call_target(self, call):
    """Resolve a self.call instance to the target it represents.

    Args:
      call: a self.call instance, e.g. self.call.adb.Shell

    Returns:
      The target object represented by the call, e.g. self.adb.Shell

    Raises:
      ValueError if the path of the call does not start with "self", i.e. the
          target of the call is external to the self object.
      AttributeError if the path of the call does not specify a valid
          chain of attributes (without any calls) starting from "self".
    """
    path = call.name.split('.')
    if path.pop(0) != 'self':
      raise ValueError("Target %r outside of 'self' object" % call.name)
    target = self
    for attr in path:
      target = getattr(target, attr)
    return target

  def patch_call(self, call, **kwargs):
    """Patch the target of a mock.call instance.

    Args:
      call: a mock.call instance identifying a target to patch
      Extra keyword arguments are processed by mock.patch

    Returns:
      A context manager to mock/unmock the target of the call
    """
    if call.name.startswith('self.'):
      target = self.call_target(call.parent)
      _, attribute = call.name.rsplit('.', 1)
      if (hasattr(type(target), attribute)
          and isinstance(getattr(type(target), attribute), property)):
        return mock.patch.object(
            type(target), attribute, new_callable=mock.PropertyMock, **kwargs)
      else:
        return mock.patch.object(target, attribute, **kwargs)
    else:
      return mock.patch(call.name, **kwargs)

  def watchCalls(self, calls):
    """Add calls to the set of watched calls.

    Args:
      calls: a sequence of mock.call instances identifying targets to watch
    """
    self._watched.update((call.name, call) for call in calls)

  def watchMethodCalls(self, call, ignore=None):
    """Watch all public methods of the target identified by a self.call.

    Args:
      call: a self.call instance indetifying an object
      ignore: a list of public methods to ignore when watching for calls
    """
    target = self.call_target(call)
    if ignore is None:
      ignore = []
    self.watchCalls(getattr(call, method)
                    for method in dir(target.__class__)
                    if not method.startswith('_') and not method in ignore)

  def clearWatched(self):
    """Clear the set of watched calls."""
    self._watched = {}

  def assertCalls(self, *calls):
    """A context manager to assert that a sequence of calls is made.

    During the assertion, a number of functions and methods will be "watched",
    and any calls made to them is expected to appear---in the exact same order,
    and with the exact same arguments---as specified by the argument |calls|.

    By default, the targets of all expected calls are watched. Further targets
    to watch may be added using watchCalls and watchMethodCalls.

    Optionaly, each call may be accompanied by an action. If the action is a
    (non-callable) value, this value will be used as the return value given to
    the caller when the matching call is found. Alternatively, if the action is
    a callable, the action will be then called with the same arguments as the
    intercepted call, so that it can provide a return value or perform other
    side effects. If the action is missing, a return value of None is assumed.

    Note that mock.Mock objects are often convenient to use as a callable
    action, e.g. to raise exceptions or return other objects which are
    themselves callable.

    Args:
      calls: each argument is either a pair (expected_call, action) or just an
          expected_call, where expected_call is a mock.call instance.

    Raises:
      AssertionError if the watched targets do not receive the exact sequence
          of calls specified. Missing calls, extra calls, and calls with
          mismatching arguments, all cause the assertion to fail.
    """
    return self._AssertCalls(self, calls, self._watched)

  def assertCall(self, call, action=None):
    return self.assertCalls((call, action))

