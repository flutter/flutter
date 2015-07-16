# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Runs a monkey test on a single device."""

import logging
import random

from pylib import constants
from pylib.base import base_test_result
from pylib.base import base_test_runner
from pylib.device import device_errors
from pylib.device import intent

_CHROME_PACKAGE = constants.PACKAGE_INFO['chrome'].package

class TestRunner(base_test_runner.BaseTestRunner):
  """A TestRunner instance runs a monkey test on a single device."""

  def __init__(self, test_options, device, _):
    super(TestRunner, self).__init__(device, None)
    self._options = test_options
    self._package = constants.PACKAGE_INFO[self._options.package].package
    self._activity = constants.PACKAGE_INFO[self._options.package].activity

  def _LaunchMonkeyTest(self):
    """Runs monkey test for a given package.

    Returns:
      Output from the monkey command on the device.
    """

    timeout_ms = self._options.event_count * self._options.throttle * 1.5

    cmd = ['monkey',
           '-p %s' % self._package,
           ' '.join(['-c %s' % c for c in self._options.category]),
           '--throttle %d' % self._options.throttle,
           '-s %d' % (self._options.seed or random.randint(1, 100)),
           '-v ' * self._options.verbose_count,
           '--monitor-native-crashes',
           '--kill-process-after-error',
           self._options.extra_args,
           '%d' % self._options.event_count]
    return self.device.RunShellCommand(' '.join(cmd), timeout=timeout_ms)

  def RunTest(self, test_name):
    """Run a Monkey test on the device.

    Args:
      test_name: String to use for logging the test result.

    Returns:
      A tuple of (TestRunResults, retry).
    """
    self.device.StartActivity(
        intent.Intent(package=self._package, activity=self._activity,
                      action='android.intent.action.MAIN'),
        blocking=True, force_stop=True)

    # Chrome crashes are not always caught by Monkey test runner.
    # Verify Chrome has the same PID before and after the test.
    before_pids = self.device.GetPids(self._package)

    # Run the test.
    output = ''
    if before_pids:
      output = '\n'.join(self._LaunchMonkeyTest())
      after_pids = self.device.GetPids(self._package)

    crashed = True
    if not self._package in before_pids:
      logging.error('Failed to start the process.')
    elif not self._package in after_pids:
      logging.error('Process %s has died.', before_pids[self._package])
    elif before_pids[self._package] != after_pids[self._package]:
      logging.error('Detected process restart %s -> %s',
                    before_pids[self._package], after_pids[self._package])
    else:
      crashed = False

    results = base_test_result.TestRunResults()
    success_pattern = 'Events injected: %d' % self._options.event_count
    if success_pattern in output and not crashed:
      result = base_test_result.BaseTestResult(
          test_name, base_test_result.ResultType.PASS, log=output)
    else:
      result = base_test_result.BaseTestResult(
          test_name, base_test_result.ResultType.FAIL, log=output)
      if 'chrome' in self._options.package:
        logging.warning('Starting MinidumpUploadService...')
        # TODO(jbudorick): Update this after upstreaming.
        minidump_intent = intent.Intent(
            action='%s.crash.ACTION_FIND_ALL' % _CHROME_PACKAGE,
            package=self._package,
            activity='%s.crash.MinidumpUploadService' % _CHROME_PACKAGE)
        try:
          self.device.RunShellCommand(
              ['am', 'startservice'] + minidump_intent.am_args,
              as_root=True, check_return=True)
        except device_errors.CommandFailedError:
          logging.exception('Failed to start MinidumpUploadService')

    results.AddResult(result)
    return results, False
