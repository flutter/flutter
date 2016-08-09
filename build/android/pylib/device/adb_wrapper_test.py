# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Tests for the AdbWrapper class."""

import os
import tempfile
import time
import unittest

from pylib.device import adb_wrapper
from pylib.device import device_errors


class TestAdbWrapper(unittest.TestCase):

  def setUp(self):
    devices = adb_wrapper.AdbWrapper.Devices()
    assert devices, 'A device must be attached'
    self._adb = devices[0]
    self._adb.WaitForDevice()

  @staticmethod
  def _MakeTempFile(contents):
    """Make a temporary file with the given contents.

    Args:
      contents: string to write to the temporary file.

    Returns:
      The absolute path to the file.
    """
    fi, path = tempfile.mkstemp()
    with os.fdopen(fi, 'wb') as f:
      f.write(contents)
    return path

  def testShell(self):
    output = self._adb.Shell('echo test', expect_status=0)
    self.assertEqual(output.strip(), 'test')
    output = self._adb.Shell('echo test')
    self.assertEqual(output.strip(), 'test')
    with self.assertRaises(device_errors.AdbCommandFailedError):
        self._adb.Shell('echo test', expect_status=1)

  def testPushLsPull(self):
    path = self._MakeTempFile('foo')
    device_path = '/data/local/tmp/testfile.txt'
    local_tmpdir = os.path.dirname(path)
    self._adb.Push(path, device_path)
    files = dict(self._adb.Ls('/data/local/tmp'))
    self.assertTrue('testfile.txt' in files)
    self.assertEquals(3, files['testfile.txt'].st_size)
    self.assertEqual(self._adb.Shell('cat %s' % device_path), 'foo')
    self._adb.Pull(device_path, local_tmpdir)
    with open(os.path.join(local_tmpdir, 'testfile.txt'), 'r') as f:
      self.assertEqual(f.read(), 'foo')

  def testInstall(self):
    path = self._MakeTempFile('foo')
    with self.assertRaises(device_errors.AdbCommandFailedError):
      self._adb.Install(path)

  def testForward(self):
    with self.assertRaises(device_errors.AdbCommandFailedError):
      self._adb.Forward(0, 0)

  def testUninstall(self):
    with self.assertRaises(device_errors.AdbCommandFailedError):
      self._adb.Uninstall('some.nonexistant.package')

  def testRebootWaitForDevice(self):
    self._adb.Reboot()
    print 'waiting for device to reboot...'
    while self._adb.GetState() == 'device':
      time.sleep(1)
    self._adb.WaitForDevice()
    self.assertEqual(self._adb.GetState(), 'device')
    print 'waiting for package manager...'
    while 'package:' not in self._adb.Shell('pm path android'):
      time.sleep(1)

  def testRootRemount(self):
    self._adb.Root()
    while True:
      try:
        self._adb.Shell('start')
        break
      except device_errors.AdbCommandFailedError:
        time.sleep(1)
    self._adb.Remount()


if __name__ == '__main__':
  unittest.main()
