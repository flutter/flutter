# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import logging
import os
import re
import tempfile

from pylib import pexpect
from pylib import ports
from pylib.base import base_test_result
from pylib.base import base_test_runner
from pylib.device import device_errors
from pylib.gtest import gtest_test_instance
from pylib.local import local_test_server_spawner
from pylib.perf import perf_control

# Test case statuses.
RE_RUN = re.compile('\\[ RUN      \\] ?(.*)\r\n')
RE_FAIL = re.compile('\\[  FAILED  \\] ?(.*?)( \\((\\d+) ms\\))?\r\r\n')
RE_OK = re.compile('\\[       OK \\] ?(.*?)( \\((\\d+) ms\\))?\r\r\n')

# Test run statuses.
RE_PASSED = re.compile('\\[  PASSED  \\] ?(.*)\r\n')
RE_RUNNER_FAIL = re.compile('\\[ RUNNER_FAILED \\] ?(.*)\r\n')
# Signal handlers are installed before starting tests
# to output the CRASHED marker when a crash happens.
RE_CRASH = re.compile('\\[ CRASHED      \\](.*)\r\n')

# Bots that don't output anything for 20 minutes get timed out, so that's our
# hard cap.
_INFRA_STDOUT_TIMEOUT = 20 * 60


def _TestSuiteRequiresMockTestServer(suite_name):
  """Returns True if the test suite requires mock test server."""
  tests_require_net_test_server = ['unit_tests', 'net_unittests',
                                   'components_browsertests',
                                   'content_unittests',
                                   'content_browsertests']
  return (suite_name in
          tests_require_net_test_server)

def _TestSuiteRequiresHighPerfMode(suite_name):
  """Returns True if the test suite requires high performance mode."""
  return 'perftests' in suite_name

class TestRunner(base_test_runner.BaseTestRunner):
  def __init__(self, test_options, device, test_package):
    """Single test suite attached to a single device.

    Args:
      test_options: A GTestOptions object.
      device: Device to run the tests.
      test_package: An instance of TestPackage class.
    """

    super(TestRunner, self).__init__(device, test_options.tool)

    self.test_package = test_package
    self.test_package.tool = self.tool
    self._test_arguments = test_options.test_arguments

    timeout = test_options.timeout
    if timeout == 0:
      timeout = 60
    # On a VM (e.g. chromium buildbots), this timeout is way too small.
    if os.environ.get('BUILDBOT_SLAVENAME'):
      timeout = timeout * 2

    self._timeout = min(timeout * self.tool.GetTimeoutScale(),
                        _INFRA_STDOUT_TIMEOUT)
    if _TestSuiteRequiresHighPerfMode(self.test_package.suite_name):
      self._perf_controller = perf_control.PerfControl(self.device)

    if _TestSuiteRequiresMockTestServer(self.test_package.suite_name):
      self._servers = [
          local_test_server_spawner.LocalTestServerSpawner(
              ports.AllocateTestServerPort(), self.device, self.tool)]
    else:
      self._servers = []

    if test_options.app_data_files:
      self._app_data_files = test_options.app_data_files
      if test_options.app_data_file_dir:
        self._app_data_file_dir = test_options.app_data_file_dir
      else:
        self._app_data_file_dir = tempfile.mkdtemp()
        logging.critical('Saving app files to %s', self._app_data_file_dir)
    else:
      self._app_data_files = None
      self._app_data_file_dir = None

  #override
  def InstallTestPackage(self):
    self.test_package.Install(self.device)

  def _ParseTestOutput(self, p):
    """Process the test output.

    Args:
      p: An instance of pexpect spawn class.

    Returns:
      A TestRunResults object.
    """
    results = base_test_result.TestRunResults()

    log = ''
    try:
      while True:
        full_test_name = None

        found = p.expect([RE_RUN, RE_PASSED, RE_RUNNER_FAIL],
                         timeout=self._timeout)
        if found == 1:  # RE_PASSED
          break
        elif found == 2:  # RE_RUNNER_FAIL
          break
        else:  # RE_RUN
          full_test_name = p.match.group(1).replace('\r', '')
          found = p.expect([RE_OK, RE_FAIL, RE_CRASH], timeout=self._timeout)
          log = p.before.replace('\r', '')
          if found == 0:  # RE_OK
            if full_test_name == p.match.group(1).replace('\r', ''):
              duration_ms = int(p.match.group(3)) if p.match.group(3) else 0
              results.AddResult(base_test_result.BaseTestResult(
                  full_test_name, base_test_result.ResultType.PASS,
                  duration=duration_ms, log=log))
          elif found == 2:  # RE_CRASH
            results.AddResult(base_test_result.BaseTestResult(
                full_test_name, base_test_result.ResultType.CRASH,
                log=log))
            break
          else:  # RE_FAIL
            duration_ms = int(p.match.group(3)) if p.match.group(3) else 0
            results.AddResult(base_test_result.BaseTestResult(
                full_test_name, base_test_result.ResultType.FAIL,
                duration=duration_ms, log=log))
    except pexpect.EOF:
      logging.error('Test terminated - EOF')
      # We're here because either the device went offline, or the test harness
      # crashed without outputting the CRASHED marker (crbug.com/175538).
      if not self.device.IsOnline():
        raise device_errors.DeviceUnreachableError(
            'Device %s went offline.' % str(self.device))
      if full_test_name:
        results.AddResult(base_test_result.BaseTestResult(
            full_test_name, base_test_result.ResultType.CRASH,
            log=p.before.replace('\r', '')))
    except pexpect.TIMEOUT:
      logging.error('Test terminated after %d second timeout.',
                    self._timeout)
      if full_test_name:
        results.AddResult(base_test_result.BaseTestResult(
            full_test_name, base_test_result.ResultType.TIMEOUT,
            log=p.before.replace('\r', '')))
    finally:
      p.close()

    ret_code = self.test_package.GetGTestReturnCode(self.device)
    if ret_code:
      logging.critical(
          'gtest exit code: %d\npexpect.before: %s\npexpect.after: %s',
          ret_code, p.before, p.after)

    return results

  #override
  def RunTest(self, test):
    test_results = base_test_result.TestRunResults()
    if not test:
      return test_results, None

    try:
      self.test_package.ClearApplicationState(self.device)
      self.test_package.CreateCommandLineFileOnDevice(
          self.device, test, self._test_arguments)
      test_results = self._ParseTestOutput(
          self.test_package.SpawnTestProcess(self.device))
      if self._app_data_files:
        self.test_package.PullAppFiles(self.device, self._app_data_files,
                                       self._app_data_file_dir)
    finally:
      for s in self._servers:
        s.Reset()
    # Calculate unknown test results.
    all_tests = set(test.split(':'))
    all_tests_ran = set([t.GetName() for t in test_results.GetAll()])
    unknown_tests = all_tests - all_tests_ran
    test_results.AddResults(
        [base_test_result.BaseTestResult(t, base_test_result.ResultType.UNKNOWN)
         for t in unknown_tests])
    retry = ':'.join([t.GetName() for t in test_results.GetNotPass()])
    return test_results, retry

  #override
  def SetUp(self):
    """Sets up necessary test enviroment for the test suite."""
    super(TestRunner, self).SetUp()
    for s in self._servers:
      s.SetUp()
    if _TestSuiteRequiresHighPerfMode(self.test_package.suite_name):
      self._perf_controller.SetHighPerfMode()
    self.tool.SetupEnvironment()

  #override
  def TearDown(self):
    """Cleans up the test enviroment for the test suite."""
    for s in self._servers:
      s.TearDown()
    if _TestSuiteRequiresHighPerfMode(self.test_package.suite_name):
      self._perf_controller.SetDefaultPerfMode()
    self.test_package.ClearApplicationState(self.device)
    self.tool.CleanUpEnvironment()
    super(TestRunner, self).TearDown()
