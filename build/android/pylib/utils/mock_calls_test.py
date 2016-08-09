#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Unit tests for the contents of mock_calls.py.
"""

import logging
import os
import sys
import unittest

from pylib import constants
from pylib.utils import mock_calls

sys.path.append(os.path.join(
    constants.DIR_SOURCE_ROOT, 'third_party', 'pymock'))
import mock # pylint: disable=F0401


class _DummyAdb(object):
  def __str__(self):
    return '0123456789abcdef'

  def Push(self, host_path, device_path):
    logging.debug('(device %s) pushing %r to %r', self, host_path, device_path)

  def IsOnline(self):
    logging.debug('(device %s) checking device online', self)
    return True

  def Shell(self, cmd):
    logging.debug('(device %s) running command %r', self, cmd)
    return "nice output\n"

  def Reboot(self):
    logging.debug('(device %s) rebooted!', self)

  @property
  def build_version_sdk(self):
    logging.debug('(device %s) getting build_version_sdk', self)
    return constants.ANDROID_SDK_VERSION_CODES.LOLLIPOP


class TestCaseWithAssertCallsTest(mock_calls.TestCase):
  def setUp(self):
    self.adb = _DummyAdb()

  def ShellError(self):
    def action(cmd):
      raise ValueError('(device %s) command %r is not nice' % (self.adb, cmd))
    return action

  def get_answer(self):
    logging.debug("called 'get_answer' of %r object", self)
    return 42

  def echo(self, thing):
    logging.debug("called 'echo' of %r object", self)
    return thing

  def testCallTarget_succeds(self):
    self.assertEquals(self.adb.Shell,
                      self.call_target(self.call.adb.Shell))

  def testCallTarget_failsExternal(self):
    with self.assertRaises(ValueError):
      self.call_target(mock.call.sys.getcwd)

  def testCallTarget_failsUnknownAttribute(self):
    with self.assertRaises(AttributeError):
      self.call_target(self.call.adb.Run)

  def testCallTarget_failsIntermediateCalls(self):
    with self.assertRaises(AttributeError):
      self.call_target(self.call.adb.RunShell('cmd').append)

  def testPatchCall_method(self):
    self.assertEquals(42, self.get_answer())
    with self.patch_call(self.call.get_answer, return_value=123):
      self.assertEquals(123, self.get_answer())
    self.assertEquals(42, self.get_answer())

  def testPatchCall_attribute_method(self):
    with self.patch_call(self.call.adb.Shell, return_value='hello'):
      self.assertEquals('hello', self.adb.Shell('echo hello'))

  def testPatchCall_global(self):
    with self.patch_call(mock.call.os.getcwd, return_value='/some/path'):
      self.assertEquals('/some/path', os.getcwd())

  def testPatchCall_withSideEffect(self):
    with self.patch_call(self.call.adb.Shell, side_effect=ValueError):
      with self.assertRaises(ValueError):
        self.adb.Shell('echo hello')

  def testPatchCall_property(self):
    self.assertEquals(constants.ANDROID_SDK_VERSION_CODES.LOLLIPOP,
                      self.adb.build_version_sdk)
    with self.patch_call(
        self.call.adb.build_version_sdk,
        return_value=constants.ANDROID_SDK_VERSION_CODES.KITKAT):
      self.assertEquals(constants.ANDROID_SDK_VERSION_CODES.KITKAT,
                        self.adb.build_version_sdk)
    self.assertEquals(constants.ANDROID_SDK_VERSION_CODES.LOLLIPOP,
                      self.adb.build_version_sdk)

  def testAssertCalls_succeeds_simple(self):
    self.assertEquals(42, self.get_answer())
    with self.assertCall(self.call.get_answer(), 123):
      self.assertEquals(123, self.get_answer())
    self.assertEquals(42, self.get_answer())

  def testAssertCalls_succeeds_multiple(self):
    with self.assertCalls(
        (mock.call.os.getcwd(), '/some/path'),
        (self.call.echo('hello'), 'hello'),
        (self.call.get_answer(), 11),
        self.call.adb.Push('this_file', 'that_file'),
        (self.call.get_answer(), 12)):
      self.assertEquals(os.getcwd(), '/some/path')
      self.assertEquals('hello', self.echo('hello'))
      self.assertEquals(11, self.get_answer())
      self.adb.Push('this_file', 'that_file')
      self.assertEquals(12, self.get_answer())

  def testAsserCalls_succeeds_withAction(self):
    with self.assertCall(
        self.call.adb.Shell('echo hello'), self.ShellError()):
      with self.assertRaises(ValueError):
        self.adb.Shell('echo hello')

  def testAssertCalls_fails_tooManyCalls(self):
    with self.assertRaises(AssertionError):
      with self.assertCalls(self.call.adb.IsOnline()):
        self.adb.IsOnline()
        self.adb.IsOnline()

  def testAssertCalls_fails_tooFewCalls(self):
    with self.assertRaises(AssertionError):
      with self.assertCalls(self.call.adb.IsOnline()):
        pass

  def testAssertCalls_succeeds_extraCalls(self):
    # we are not watching Reboot, so the assertion succeeds
    with self.assertCalls(self.call.adb.IsOnline()):
      self.adb.IsOnline()
      self.adb.Reboot()

  def testAssertCalls_fails_extraCalls(self):
    self.watchCalls([self.call.adb.Reboot])
    # this time we are also watching Reboot, so the assertion fails
    with self.assertRaises(AssertionError):
      with self.assertCalls(self.call.adb.IsOnline()):
        self.adb.IsOnline()
        self.adb.Reboot()

  def testAssertCalls_succeeds_NoCalls(self):
    self.watchMethodCalls(self.call.adb) # we are watching all adb methods
    with self.assertCalls():
      pass

  def testAssertCalls_fails_NoCalls(self):
    self.watchMethodCalls(self.call.adb)
    with self.assertRaises(AssertionError):
      with self.assertCalls():
        self.adb.IsOnline()


if __name__ == '__main__':
  logging.getLogger().setLevel(logging.DEBUG)
  unittest.main(verbosity=2)

