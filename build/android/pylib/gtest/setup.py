# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Generates test runner factory and tests for GTests."""
# pylint: disable=W0212

import logging
import os
import sys

from pylib import constants

from pylib.base import base_setup
from pylib.base import base_test_result
from pylib.base import test_dispatcher
from pylib.device import device_utils
from pylib.gtest import gtest_test_instance
from pylib.gtest import test_package_apk
from pylib.gtest import test_package_exe
from pylib.gtest import test_runner

sys.path.insert(0,
                os.path.join(constants.DIR_SOURCE_ROOT, 'build', 'util', 'lib',
                             'common'))
import unittest_util # pylint: disable=F0401


ISOLATE_FILE_PATHS = gtest_test_instance._DEFAULT_ISOLATE_FILE_PATHS


# Used for filtering large data deps at a finer grain than what's allowed in
# isolate files since pushing deps to devices is expensive.
# Wildcards are allowed.
DEPS_EXCLUSION_LIST = [
    'chrome/test/data/extensions/api_test',
    'chrome/test/data/extensions/secure_shell',
    'chrome/test/data/firefox*',
    'chrome/test/data/gpu',
    'chrome/test/data/image_decoding',
    'chrome/test/data/import',
    'chrome/test/data/page_cycler',
    'chrome/test/data/perf',
    'chrome/test/data/pyauto_private',
    'chrome/test/data/safari_import',
    'chrome/test/data/scroll',
    'chrome/test/data/third_party',
    'third_party/hunspell_dictionaries/*.dic',
    # crbug.com/258690
    'webkit/data/bmp_decoder',
    'webkit/data/ico_decoder',
]


def _GetDisabledTestsFilterFromFile(suite_name):
  """Returns a gtest filter based on the *_disabled file.

  Args:
    suite_name: Name of the test suite (e.g. base_unittests).

  Returns:
    A gtest filter which excludes disabled tests.
    Example: '*-StackTrace.*:StringPrintfTest.StringPrintfMisc'
  """
  filter_file_path = os.path.join(
      os.path.abspath(os.path.dirname(__file__)),
      'filter', '%s_disabled' % suite_name)

  if not filter_file_path or not os.path.exists(filter_file_path):
    logging.info('No filter file found at %s', filter_file_path)
    return '*'

  filters = [x for x in [x.strip() for x in file(filter_file_path).readlines()]
             if x and x[0] != '#']
  disabled_filter = '*-%s' % ':'.join(filters)
  logging.info('Applying filter "%s" obtained from %s',
               disabled_filter, filter_file_path)
  return disabled_filter


def _GetTests(test_options, test_package, devices):
  """Get a list of tests.

  Args:
    test_options: A GTestOptions object.
    test_package: A TestPackageApk object.
    devices: A list of attached devices.

  Returns:
    A list of all the tests in the test suite.
  """
  class TestListResult(base_test_result.BaseTestResult):
    def __init__(self):
      super(TestListResult, self).__init__(
          'gtest_list_tests', base_test_result.ResultType.PASS)
      self.test_list = []

  def TestListerRunnerFactory(device, _shard_index):
    class TestListerRunner(test_runner.TestRunner):
      def RunTest(self, _test):
        result = TestListResult()
        self.test_package.Install(self.device)
        result.test_list = self.test_package.GetAllTests(self.device)
        results = base_test_result.TestRunResults()
        results.AddResult(result)
        return results, None
    return TestListerRunner(test_options, device, test_package)

  results, _no_retry = test_dispatcher.RunTests(
      ['gtest_list_tests'], TestListerRunnerFactory, devices)
  tests = []
  for r in results.GetAll():
    tests.extend(r.test_list)
  return tests


def _FilterTestsUsingPrefixes(all_tests, pre=False, manual=False):
  """Removes tests with disabled prefixes.

  Args:
    all_tests: List of tests to filter.
    pre: If True, include tests with PRE_ prefix.
    manual: If True, include tests with MANUAL_ prefix.

  Returns:
    List of tests remaining.
  """
  filtered_tests = []
  filter_prefixes = ['DISABLED_', 'FLAKY_', 'FAILS_']

  if not pre:
    filter_prefixes.append('PRE_')

  if not manual:
    filter_prefixes.append('MANUAL_')

  for t in all_tests:
    test_case, test = t.split('.', 1)
    if not any([test_case.startswith(prefix) or test.startswith(prefix) for
                prefix in filter_prefixes]):
      filtered_tests.append(t)
  return filtered_tests


def _FilterDisabledTests(tests, suite_name, has_gtest_filter):
  """Removes disabled tests from |tests|.

  Applies the following filters in order:
    1. Remove tests with disabled prefixes.
    2. Remove tests specified in the *_disabled files in the 'filter' dir

  Args:
    tests: List of tests.
    suite_name: Name of the test suite (e.g. base_unittests).
    has_gtest_filter: Whether a gtest_filter is provided.

  Returns:
    List of tests remaining.
  """
  tests = _FilterTestsUsingPrefixes(
      tests, has_gtest_filter, has_gtest_filter)
  tests = unittest_util.FilterTestNames(
      tests, _GetDisabledTestsFilterFromFile(suite_name))

  return tests


def Setup(test_options, devices):
  """Create the test runner factory and tests.

  Args:
    test_options: A GTestOptions object.
    devices: A list of attached devices.

  Returns:
    A tuple of (TestRunnerFactory, tests).
  """
  test_package = test_package_apk.TestPackageApk(test_options.suite_name)
  if not os.path.exists(test_package.suite_path):
    exe_test_package = test_package_exe.TestPackageExecutable(
        test_options.suite_name)
    if not os.path.exists(exe_test_package.suite_path):
      raise Exception(
          'Did not find %s target. Ensure it has been built.\n'
          '(not found at %s or %s)'
          % (test_options.suite_name,
             test_package.suite_path,
             exe_test_package.suite_path))
    test_package = exe_test_package
  logging.warning('Found target %s', test_package.suite_path)

  i = base_setup.GenerateDepsDirUsingIsolate(test_options.suite_name,
                                         test_options.isolate_file_path,
                                         ISOLATE_FILE_PATHS,
                                         DEPS_EXCLUSION_LIST)
  def push_data_deps_to_device_dir(device):
    device_dir = (constants.TEST_EXECUTABLE_DIR
        if test_package.suite_name == 'breakpad_unittests'
        else device.GetExternalStoragePath())
    base_setup.PushDataDeps(device, device_dir, test_options)
  device_utils.DeviceUtils.parallel(devices).pMap(push_data_deps_to_device_dir)
  if i:
    i.Clear()

  tests = _GetTests(test_options, test_package, devices)

  # Constructs a new TestRunner with the current options.
  def TestRunnerFactory(device, _shard_index):
    return test_runner.TestRunner(
        test_options,
        device,
        test_package)

  if test_options.run_disabled:
    test_options = test_options._replace(
        test_arguments=('%s --gtest_also_run_disabled_tests' %
                        test_options.test_arguments))
  else:
    tests = _FilterDisabledTests(tests, test_options.suite_name,
                                 bool(test_options.gtest_filter))
  if test_options.gtest_filter:
    tests = unittest_util.FilterTestNames(tests, test_options.gtest_filter)

  # Coalesce unit tests into a single test per device
  if test_options.suite_name not in gtest_test_instance.BROWSER_TEST_SUITES:
    num_devices = len(devices)
    tests = [':'.join(tests[i::num_devices]) for i in xrange(num_devices)]
    tests = [t for t in tests if t]

  return (TestRunnerFactory, tests)
