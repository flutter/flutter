# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Unit tests for decorators.py.
"""

# pylint: disable=W0613

import os
import sys
import time
import traceback
import unittest

from pylib import constants
from pylib.device import decorators
from pylib.device import device_errors
from pylib.utils import reraiser_thread

# TODO(jbudorick) Remove once the DeviceUtils implementations are no longer
#                 backed by AndroidCommands / android_testrunner.
sys.path.append(os.path.join(constants.DIR_SOURCE_ROOT, 'third_party',
                             'android_testrunner'))
import errors as old_errors

_DEFAULT_TIMEOUT = 30
_DEFAULT_RETRIES = 3

class DecoratorsTest(unittest.TestCase):
  _decorated_function_called_count = 0

  def testFunctionDecoratorDoesTimeouts(self):
    """Tests that the base decorator handles the timeout logic."""
    DecoratorsTest._decorated_function_called_count = 0
    @decorators.WithTimeoutAndRetries
    def alwaysTimesOut(timeout=None, retries=None):
      DecoratorsTest._decorated_function_called_count += 1
      time.sleep(100)

    start_time = time.time()
    with self.assertRaises(device_errors.CommandTimeoutError):
      alwaysTimesOut(timeout=1, retries=0)
    elapsed_time = time.time() - start_time
    self.assertTrue(elapsed_time >= 1)
    self.assertEquals(1, DecoratorsTest._decorated_function_called_count)

  def testFunctionDecoratorDoesRetries(self):
    """Tests that the base decorator handles the retries logic."""
    DecoratorsTest._decorated_function_called_count = 0
    @decorators.WithTimeoutAndRetries
    def alwaysRaisesCommandFailedError(timeout=None, retries=None):
      DecoratorsTest._decorated_function_called_count += 1
      raise device_errors.CommandFailedError('testCommand failed')

    with self.assertRaises(device_errors.CommandFailedError):
      alwaysRaisesCommandFailedError(timeout=30, retries=10)
    self.assertEquals(11, DecoratorsTest._decorated_function_called_count)

  def testFunctionDecoratorRequiresParams(self):
    """Tests that the base decorator requires timeout and retries params."""
    @decorators.WithTimeoutAndRetries
    def requiresExplicitTimeoutAndRetries(timeout=None, retries=None):
      return (timeout, retries)

    with self.assertRaises(KeyError):
      requiresExplicitTimeoutAndRetries()
    with self.assertRaises(KeyError):
      requiresExplicitTimeoutAndRetries(timeout=10)
    with self.assertRaises(KeyError):
      requiresExplicitTimeoutAndRetries(retries=0)
    expected_timeout = 10
    expected_retries = 1
    (actual_timeout, actual_retries) = (
        requiresExplicitTimeoutAndRetries(timeout=expected_timeout,
                                          retries=expected_retries))
    self.assertEquals(expected_timeout, actual_timeout)
    self.assertEquals(expected_retries, actual_retries)

  def testFunctionDecoratorTranslatesOldExceptions(self):
    """Tests that the explicit decorator translates old exceptions."""
    @decorators.WithTimeoutAndRetries
    def alwaysRaisesProvidedException(exception, timeout=None, retries=None):
      raise exception

    exception_desc = 'Old response timeout error'
    with self.assertRaises(device_errors.CommandTimeoutError) as e:
      alwaysRaisesProvidedException(
          old_errors.WaitForResponseTimedOutError(exception_desc),
          timeout=10, retries=1)
    self.assertEquals(exception_desc, str(e.exception))

    exception_desc = 'Old device error'
    with self.assertRaises(device_errors.DeviceUnreachableError) as e:
      alwaysRaisesProvidedException(
          old_errors.DeviceUnresponsiveError(exception_desc),
          timeout=10, retries=1)
    self.assertEquals(exception_desc, str(e.exception))

  def testFunctionDecoratorTranslatesReraiserExceptions(self):
    """Tests that the explicit decorator translates reraiser exceptions."""
    @decorators.WithTimeoutAndRetries
    def alwaysRaisesProvidedException(exception, timeout=None, retries=None):
      raise exception

    exception_desc = 'Reraiser thread timeout error'
    with self.assertRaises(device_errors.CommandTimeoutError) as e:
      alwaysRaisesProvidedException(
          reraiser_thread.TimeoutError(exception_desc),
          timeout=10, retries=1)
    self.assertEquals(exception_desc, str(e.exception))

  def testDefaultsFunctionDecoratorDoesTimeouts(self):
    """Tests that the defaults decorator handles timeout logic."""
    DecoratorsTest._decorated_function_called_count = 0
    @decorators.WithTimeoutAndRetriesDefaults(1, 0)
    def alwaysTimesOut(timeout=None, retries=None):
      DecoratorsTest._decorated_function_called_count += 1
      time.sleep(100)

    start_time = time.time()
    with self.assertRaises(device_errors.CommandTimeoutError):
      alwaysTimesOut()
    elapsed_time = time.time() - start_time
    self.assertTrue(elapsed_time >= 1)
    self.assertEquals(1, DecoratorsTest._decorated_function_called_count)

    DecoratorsTest._decorated_function_called_count = 0
    with self.assertRaises(device_errors.CommandTimeoutError):
      alwaysTimesOut(timeout=2)
    elapsed_time = time.time() - start_time
    self.assertTrue(elapsed_time >= 2)
    self.assertEquals(1, DecoratorsTest._decorated_function_called_count)

  def testDefaultsFunctionDecoratorDoesRetries(self):
    """Tests that the defaults decorator handles retries logic."""
    DecoratorsTest._decorated_function_called_count = 0
    @decorators.WithTimeoutAndRetriesDefaults(30, 10)
    def alwaysRaisesCommandFailedError(timeout=None, retries=None):
      DecoratorsTest._decorated_function_called_count += 1
      raise device_errors.CommandFailedError('testCommand failed')

    with self.assertRaises(device_errors.CommandFailedError):
      alwaysRaisesCommandFailedError()
    self.assertEquals(11, DecoratorsTest._decorated_function_called_count)

    DecoratorsTest._decorated_function_called_count = 0
    with self.assertRaises(device_errors.CommandFailedError):
      alwaysRaisesCommandFailedError(retries=5)
    self.assertEquals(6, DecoratorsTest._decorated_function_called_count)

  def testDefaultsFunctionDecoratorPassesValues(self):
    """Tests that the defaults decorator passes timeout and retries kwargs."""
    @decorators.WithTimeoutAndRetriesDefaults(30, 10)
    def alwaysReturnsTimeouts(timeout=None, retries=None):
      return timeout

    self.assertEquals(30, alwaysReturnsTimeouts())
    self.assertEquals(120, alwaysReturnsTimeouts(timeout=120))

    @decorators.WithTimeoutAndRetriesDefaults(30, 10)
    def alwaysReturnsRetries(timeout=None, retries=None):
      return retries

    self.assertEquals(10, alwaysReturnsRetries())
    self.assertEquals(1, alwaysReturnsRetries(retries=1))

  def testDefaultsFunctionDecoratorTranslatesOldExceptions(self):
    """Tests that the explicit decorator translates old exceptions."""
    @decorators.WithTimeoutAndRetriesDefaults(30, 10)
    def alwaysRaisesProvidedException(exception, timeout=None, retries=None):
      raise exception

    exception_desc = 'Old response timeout error'
    with self.assertRaises(device_errors.CommandTimeoutError) as e:
      alwaysRaisesProvidedException(
          old_errors.WaitForResponseTimedOutError(exception_desc))
    self.assertEquals(exception_desc, str(e.exception))

    exception_desc = 'Old device error'
    with self.assertRaises(device_errors.DeviceUnreachableError) as e:
      alwaysRaisesProvidedException(
          old_errors.DeviceUnresponsiveError(exception_desc))
    self.assertEquals(exception_desc, str(e.exception))

  def testDefaultsFunctionDecoratorTranslatesReraiserExceptions(self):
    """Tests that the explicit decorator translates reraiser exceptions."""
    @decorators.WithTimeoutAndRetriesDefaults(30, 10)
    def alwaysRaisesProvidedException(exception, timeout=None, retries=None):
      raise exception

    exception_desc = 'Reraiser thread timeout error'
    with self.assertRaises(device_errors.CommandTimeoutError) as e:
      alwaysRaisesProvidedException(
          reraiser_thread.TimeoutError(exception_desc))
    self.assertEquals(exception_desc, str(e.exception))

  def testExplicitFunctionDecoratorDoesTimeouts(self):
    """Tests that the explicit decorator handles timeout logic."""
    DecoratorsTest._decorated_function_called_count = 0
    @decorators.WithExplicitTimeoutAndRetries(1, 0)
    def alwaysTimesOut():
      DecoratorsTest._decorated_function_called_count += 1
      time.sleep(100)

    start_time = time.time()
    with self.assertRaises(device_errors.CommandTimeoutError):
      alwaysTimesOut()
    elapsed_time = time.time() - start_time
    self.assertTrue(elapsed_time >= 1)
    self.assertEquals(1, DecoratorsTest._decorated_function_called_count)

  def testExplicitFunctionDecoratorDoesRetries(self):
    """Tests that the explicit decorator handles retries logic."""
    DecoratorsTest._decorated_function_called_count = 0
    @decorators.WithExplicitTimeoutAndRetries(30, 10)
    def alwaysRaisesCommandFailedError():
      DecoratorsTest._decorated_function_called_count += 1
      raise device_errors.CommandFailedError('testCommand failed')

    with self.assertRaises(device_errors.CommandFailedError):
      alwaysRaisesCommandFailedError()
    self.assertEquals(11, DecoratorsTest._decorated_function_called_count)

  def testExplicitDecoratorTranslatesOldExceptions(self):
    """Tests that the explicit decorator translates old exceptions."""
    @decorators.WithExplicitTimeoutAndRetries(30, 10)
    def alwaysRaisesProvidedException(exception):
      raise exception

    exception_desc = 'Old response timeout error'
    with self.assertRaises(device_errors.CommandTimeoutError) as e:
      alwaysRaisesProvidedException(
          old_errors.WaitForResponseTimedOutError(exception_desc))
    self.assertEquals(exception_desc, str(e.exception))

    exception_desc = 'Old device error'
    with self.assertRaises(device_errors.DeviceUnreachableError) as e:
      alwaysRaisesProvidedException(
          old_errors.DeviceUnresponsiveError(exception_desc))
    self.assertEquals(exception_desc, str(e.exception))

  def testExplicitDecoratorTranslatesReraiserExceptions(self):
    """Tests that the explicit decorator translates reraiser exceptions."""
    @decorators.WithExplicitTimeoutAndRetries(30, 10)
    def alwaysRaisesProvidedException(exception):
      raise exception

    exception_desc = 'Reraiser thread timeout error'
    with self.assertRaises(device_errors.CommandTimeoutError) as e:
      alwaysRaisesProvidedException(
          reraiser_thread.TimeoutError(exception_desc))
    self.assertEquals(exception_desc, str(e.exception))

  class _MethodDecoratorTestObject(object):
    """An object suitable for testing the method decorator."""

    def __init__(self, test_case, default_timeout=_DEFAULT_TIMEOUT,
                 default_retries=_DEFAULT_RETRIES):
      self._test_case = test_case
      self.default_timeout = default_timeout
      self.default_retries = default_retries
      self.function_call_counters = {
          'alwaysRaisesCommandFailedError': 0,
          'alwaysTimesOut': 0,
          'requiresExplicitTimeoutAndRetries': 0,
      }

    @decorators.WithTimeoutAndRetriesFromInstance(
        'default_timeout', 'default_retries')
    def alwaysTimesOut(self, timeout=None, retries=None):
      self.function_call_counters['alwaysTimesOut'] += 1
      time.sleep(100)
      self._test_case.assertFalse(True, msg='Failed to time out?')

    @decorators.WithTimeoutAndRetriesFromInstance(
        'default_timeout', 'default_retries')
    def alwaysRaisesCommandFailedError(self, timeout=None, retries=None):
      self.function_call_counters['alwaysRaisesCommandFailedError'] += 1
      raise device_errors.CommandFailedError('testCommand failed')

    # pylint: disable=no-self-use

    @decorators.WithTimeoutAndRetriesFromInstance(
        'default_timeout', 'default_retries')
    def alwaysReturnsTimeout(self, timeout=None, retries=None):
      return timeout

    @decorators.WithTimeoutAndRetriesFromInstance(
        'default_timeout', 'default_retries')
    def alwaysReturnsRetries(self, timeout=None, retries=None):
      return retries

    @decorators.WithTimeoutAndRetriesFromInstance(
        'default_timeout', 'default_retries')
    def alwaysRaisesProvidedException(self, exception, timeout=None,
                                      retries=None):
      raise exception

    # pylint: enable=no-self-use


  def testMethodDecoratorDoesTimeout(self):
    """Tests that the method decorator handles timeout logic."""
    test_obj = self._MethodDecoratorTestObject(self)
    start_time = time.time()
    with self.assertRaises(device_errors.CommandTimeoutError):
      try:
        test_obj.alwaysTimesOut(timeout=1, retries=0)
      except:
        traceback.print_exc()
        raise
    elapsed_time = time.time() - start_time
    self.assertTrue(elapsed_time >= 1)
    self.assertEquals(1, test_obj.function_call_counters['alwaysTimesOut'])

  def testMethodDecoratorDoesRetries(self):
    """Tests that the method decorator handles retries logic."""
    test_obj = self._MethodDecoratorTestObject(self)
    with self.assertRaises(device_errors.CommandFailedError):
      try:
        test_obj.alwaysRaisesCommandFailedError(retries=10)
      except:
        traceback.print_exc()
        raise
    self.assertEquals(
        11, test_obj.function_call_counters['alwaysRaisesCommandFailedError'])

  def testMethodDecoratorPassesValues(self):
    """Tests that the method decorator passes timeout and retries kwargs."""
    test_obj = self._MethodDecoratorTestObject(
        self, default_timeout=42, default_retries=31)
    self.assertEquals(42, test_obj.alwaysReturnsTimeout())
    self.assertEquals(41, test_obj.alwaysReturnsTimeout(timeout=41))
    self.assertEquals(31, test_obj.alwaysReturnsRetries())
    self.assertEquals(32, test_obj.alwaysReturnsRetries(retries=32))

  def testMethodDecoratorTranslatesOldExceptions(self):
    test_obj = self._MethodDecoratorTestObject(self)

    exception_desc = 'Old response timeout error'
    with self.assertRaises(device_errors.CommandTimeoutError) as e:
      test_obj.alwaysRaisesProvidedException(
          old_errors.WaitForResponseTimedOutError(exception_desc))
    self.assertEquals(exception_desc, str(e.exception))

    exception_desc = 'Old device error'
    with self.assertRaises(device_errors.DeviceUnreachableError) as e:
      test_obj.alwaysRaisesProvidedException(
          old_errors.DeviceUnresponsiveError(exception_desc))
    self.assertEquals(exception_desc, str(e.exception))

  def testMethodDecoratorTranslatesReraiserExceptions(self):
    test_obj = self._MethodDecoratorTestObject(self)

    exception_desc = 'Reraiser thread timeout error'
    with self.assertRaises(device_errors.CommandTimeoutError) as e:
      test_obj.alwaysRaisesProvidedException(
          reraiser_thread.TimeoutError(exception_desc))
    self.assertEquals(exception_desc, str(e.exception))

if __name__ == '__main__':
  unittest.main(verbosity=2)

