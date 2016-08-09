# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Defines TestPackageApk to help run APK-based native tests."""
# pylint: disable=W0212

import itertools
import logging
import os
import posixpath
import shlex
import sys
import tempfile
import time

from pylib import android_commands
from pylib import constants
from pylib import pexpect
from pylib.device import device_errors
from pylib.device import intent
from pylib.gtest import gtest_test_instance
from pylib.gtest import local_device_gtest_run
from pylib.gtest.test_package import TestPackage


class TestPackageApk(TestPackage):
  """A helper class for running APK-based native tests."""

  def __init__(self, suite_name):
    """
    Args:
      suite_name: Name of the test suite (e.g. base_unittests).
    """
    TestPackage.__init__(self, suite_name)
    self.suite_path = os.path.join(
        constants.GetOutDirectory(), '%s_apk' % suite_name,
        '%s-debug.apk' % suite_name)
    if suite_name == 'content_browsertests':
      self._package_info = constants.PACKAGE_INFO['content_browsertests']
    elif suite_name == 'components_browsertests':
      self._package_info = constants.PACKAGE_INFO['components_browsertests']
    else:
      self._package_info = constants.PACKAGE_INFO['gtest']

    if suite_name == 'net_unittests':
      self._extras = {'RunInSubThread': ''}
    else:
      self._extras = []

  def _CreateCommandLineFileOnDevice(self, device, options):
    device.WriteFile(self._package_info.cmdline_file,
                     self.suite_name + ' ' + options)

  def _GetFifo(self):
    # The test.fifo path is determined by:
    # testing/android/native_test/java/src/org/chromium/native_test/
    #     NativeTestActivity.java and
    # testing/android/native_test_launcher.cc
    return '/data/data/' + self._package_info.package + '/files/test.fifo'

  def _ClearFifo(self, device):
    device.RunShellCommand('rm -f ' + self._GetFifo())

  def _WatchFifo(self, device, timeout, logfile=None):
    for i in range(100):
      if device.FileExists(self._GetFifo()):
        logging.info('Fifo created. Slept for %f secs' % (i * 0.5))
        break
      time.sleep(0.5)
    else:
      raise device_errors.DeviceUnreachableError(
          'Unable to find fifo on device %s ' % self._GetFifo())
    args = shlex.split(device.old_interface.Adb()._target_arg)
    args += ['shell', 'cat', self._GetFifo()]
    return pexpect.spawn('adb', args, timeout=timeout, logfile=logfile)

  def _StartActivity(self, device, force_stop=True):
    device.StartActivity(
        intent.Intent(package=self._package_info.package,
                      activity=self._package_info.activity,
                      action='android.intent.action.MAIN',
                      extras=self._extras),
        # No wait since the runner waits for FIFO creation anyway.
        blocking=False,
        force_stop=force_stop)

  #override
  def ClearApplicationState(self, device):
    device.ClearApplicationState(self._package_info.package)
    # Content shell creates a profile on the sdscard which accumulates cache
    # files over time.
    if self.suite_name == 'content_browsertests':
      try:
        device.RunShellCommand(
            'rm -r %s/content_shell' % device.GetExternalStoragePath(),
            timeout=60 * 2)
      except device_errors.CommandFailedError:
        # TODO(jbudorick) Handle this exception appropriately once the
        #                 conversions are done.
        pass
    elif self.suite_name == 'components_browsertests':
      try:
        device.RunShellCommand(
            'rm -r %s/components_shell' % device.GetExternalStoragePath(),
            timeout=60 * 2)
      except device_errors.CommandFailedError:
        # TODO(jbudorick) Handle this exception appropriately once the
        #                 conversions are done.
        pass

  #override
  def CreateCommandLineFileOnDevice(self, device, test_filter, test_arguments):
    self._CreateCommandLineFileOnDevice(
        device, '--gtest_filter=%s %s' % (test_filter, test_arguments))

  #override
  def GetAllTests(self, device):
    self._CreateCommandLineFileOnDevice(device, '--gtest_list_tests')
    try:
      self.tool.SetupEnvironment()
      # Clear and start monitoring logcat.
      self._ClearFifo(device)
      self._StartActivity(device)
      # Wait for native test to complete.
      p = self._WatchFifo(device, timeout=30 * self.tool.GetTimeoutScale())
      p.expect('<<ScopedMainEntryLogger')
      p.close()
    finally:
      self.tool.CleanUpEnvironment()
    # We need to strip the trailing newline.
    content = [line.rstrip() for line in p.before.splitlines()]
    return gtest_test_instance.ParseGTestListTests(content)

  #override
  def SpawnTestProcess(self, device):
    try:
      self.tool.SetupEnvironment()
      self._ClearFifo(device)
      # Doesn't need to stop an Activity because ClearApplicationState() is
      # always called before this call and so it is already stopped at this
      # point.
      self._StartActivity(device, force_stop=False)
    finally:
      self.tool.CleanUpEnvironment()
    logfile = android_commands.NewLineNormalizer(sys.stdout)
    return self._WatchFifo(device, timeout=10, logfile=logfile)

  #override
  def Install(self, device):
    self.tool.CopyFiles(device)
    device.Install(self.suite_path)

  #override
  def PullAppFiles(self, device, files, directory):
    local_device_gtest_run.PullAppFilesImpl(
        device, self._package_info.package, files, directory)
