# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Generates test runner factory and tests for instrumentation tests."""

import logging
import os

from pylib import constants
from pylib import valgrind_tools

from pylib.base import base_setup
from pylib.device import device_utils
from pylib.instrumentation import test_package
from pylib.instrumentation import test_runner

DEVICE_DATA_DIR = 'chrome/test/data'

ISOLATE_FILE_PATHS = {
    'AndroidWebViewTest': 'android_webview/android_webview_test_apk.isolate',
    'ChromeShellTest': 'chrome/chrome_shell_test_apk.isolate',
    'ContentShellTest': 'content/content_shell_test_apk.isolate',
}

DEPS_EXCLUSION_LIST = []

# TODO(mikecase): Remove this function and the constant DEVICE_DATA_DIR
# once all data deps are pushed to the same location on the device.
def _PushExtraSuiteDataDeps(device, test_apk):
  """Pushes some extra data files/dirs needed by some test suite.

  Args:
    test_apk: The test suite basename for which to return file paths.
  """
  if test_apk in ['ChromeTest', 'ContentShellTest']:
    test_files = 'net/data/ssl/certificates'
    host_device_file_tuple = [
        (os.path.join(constants.DIR_SOURCE_ROOT, test_files),
         os.path.join(device.GetExternalStoragePath(), test_files))]
    device.PushChangedFiles(host_device_file_tuple)


# TODO(mikecase): Remove this function once everything uses
# base_setup.PushDataDeps to push data deps to the device.
def _PushDataDeps(device, test_options):
  valgrind_tools.PushFilesForTool(test_options.tool, device)

  host_device_file_tuples = []
  for dest_host_pair in test_options.test_data:
    dst_src = dest_host_pair.split(':', 1)
    dst_layer = dst_src[0]
    host_src = dst_src[1]
    host_test_files_path = os.path.join(constants.DIR_SOURCE_ROOT, host_src)
    if os.path.exists(host_test_files_path):
      host_device_file_tuples += [(
          host_test_files_path,
          '%s/%s/%s' % (
              device.GetExternalStoragePath(),
              DEVICE_DATA_DIR,
              dst_layer))]
  if host_device_file_tuples:
    device.PushChangedFiles(host_device_file_tuples)


def Setup(test_options, devices):
  """Create and return the test runner factory and tests.

  Args:
    test_options: An InstrumentationOptions object.

  Returns:
    A tuple of (TestRunnerFactory, tests).
  """
  if (test_options.coverage_dir and not
      os.path.exists(test_options.coverage_dir)):
    os.makedirs(test_options.coverage_dir)

  test_pkg = test_package.TestPackage(test_options.test_apk_path,
                                      test_options.test_apk_jar_path,
                                      test_options.test_support_apk_path)
  tests = test_pkg.GetAllMatchingTests(
      test_options.annotations,
      test_options.exclude_annotations,
      test_options.test_filter)
  if not tests:
    logging.error('No instrumentation tests to run with current args.')

  if test_options.test_data:
    device_utils.DeviceUtils.parallel(devices).pMap(
        _PushDataDeps, test_options)

  if test_options.isolate_file_path:
    i = base_setup.GenerateDepsDirUsingIsolate(test_options.test_apk,
                                           test_options.isolate_file_path,
                                           ISOLATE_FILE_PATHS,
                                           DEPS_EXCLUSION_LIST)
    def push_data_deps_to_device_dir(device):
      base_setup.PushDataDeps(device, device.GetExternalStoragePath(),
                              test_options)
    device_utils.DeviceUtils.parallel(devices).pMap(
        push_data_deps_to_device_dir)
    if i:
      i.Clear()

  device_utils.DeviceUtils.parallel(devices).pMap(
      _PushExtraSuiteDataDeps, test_options.test_apk)

  def TestRunnerFactory(device, shard_index):
    return test_runner.TestRunner(test_options, device, shard_index,
                                  test_pkg)

  return (TestRunnerFactory, tests)
