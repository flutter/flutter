#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Unit tests for the contents of device_temp_file.py.
"""

import logging
import os
import sys
import unittest

from pylib import constants
from pylib.device import adb_wrapper
from pylib.device import device_errors
from pylib.utils import device_temp_file
from pylib.utils import mock_calls

sys.path.append(os.path.join(
    constants.DIR_SOURCE_ROOT, 'third_party', 'pymock'))
import mock # pylint: disable=F0401

class DeviceTempFileTest(mock_calls.TestCase):

  def setUp(self):
    test_serial = '0123456789abcdef'
    self.adb = mock.Mock(spec=adb_wrapper.AdbWrapper)
    self.adb.__str__ = mock.Mock(return_value=test_serial)
    self.watchMethodCalls(self.call.adb)

  def mockShellCall(self, cmd_prefix, action=''):
    """Expect an adb.Shell(cmd) call with cmd_prefix and do some action

    Args:
      cmd_prefix: A string, the cmd of the received call is expected to have
          this as a prefix.
      action: If callable, an action to perform when the expected call is
          received, otherwise a return value.
    Returns:
      An (expected_call, action) pair suitable for use in assertCalls.
    """
    def check_and_return(cmd):
      self.assertTrue(
          cmd.startswith(cmd_prefix),
          'command %r does not start with prefix %r' % (cmd, cmd_prefix))
      if callable(action):
        return action(cmd)
      else:
        return action
    return (self.call.adb.Shell(mock.ANY), check_and_return)

  def mockExistsTest(self, exists_result):
    def action(cmd):
      if exists_result:
        return ''
      else:
        raise device_errors.AdbCommandFailedError(
            cmd, 'File not found', 1, str(self.adb))
    return self.mockShellCall('test -e ', action)

  def testTempFileNameAlreadyExists(self):
    with self.assertCalls(
        self.mockShellCall('test -d /data/local/tmp'),
        self.mockExistsTest(True),
        self.mockExistsTest(True),
        self.mockExistsTest(True),
        self.mockExistsTest(False),
        self.mockShellCall('touch '),
        self.mockShellCall('rm -f ')):
      with device_temp_file.DeviceTempFile(self.adb) as tmpfile:
        logging.debug('Temp file name: %s' % tmpfile.name)

  def testTempFileLifecycle(self):
    with self.assertCalls(
        self.mockShellCall('test -d /data/local/tmp'),
        self.mockExistsTest(False),
        self.mockShellCall('touch ')):
      tempFileContextManager = device_temp_file.DeviceTempFile(self.adb)
    with mock.patch.object(self.adb, 'Shell'):
      with tempFileContextManager as tmpfile:
        logging.debug('Temp file name: %s' % tmpfile.name)
        self.assertEquals(0, self.adb.Shell.call_count)
      self.assertEquals(1, self.adb.Shell.call_count)
      args, _ = self.adb.Shell.call_args
      self.assertTrue(args[0].startswith('rm -f '))

if __name__ == '__main__':
  logging.getLogger().setLevel(logging.DEBUG)
  unittest.main(verbosity=2)
