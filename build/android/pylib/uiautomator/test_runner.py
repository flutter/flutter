# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Class for running uiautomator tests on a single device."""

from pylib import constants
from pylib import flag_changer
from pylib.device import intent
from pylib.instrumentation import test_options as instr_test_options
from pylib.instrumentation import test_runner as instr_test_runner


class TestRunner(instr_test_runner.TestRunner):
  """Responsible for running a series of tests connected to a single device."""

  def __init__(self, test_options, device, shard_index, test_pkg):
    """Create a new TestRunner.

    Args:
      test_options: A UIAutomatorOptions object.
      device: Attached android device.
      shard_index: Shard index.
      test_pkg: A TestPackage object.
    """
    # Create an InstrumentationOptions object to pass to the super class
    instrumentation_options = instr_test_options.InstrumentationOptions(
        test_options.tool,
        test_options.annotations,
        test_options.exclude_annotations,
        test_options.test_filter,
        test_options.test_data,
        test_options.save_perf_json,
        test_options.screenshot_failures,
        wait_for_debugger=False,
        coverage_dir=None,
        test_apk=None,
        test_apk_path=None,
        test_apk_jar_path=None,
        test_runner=None,
        test_support_apk_path=None,
        device_flags=None,
        isolate_file_path=None,
        set_asserts=test_options.set_asserts,
        delete_stale_data=False)
    super(TestRunner, self).__init__(instrumentation_options, device,
                                     shard_index, test_pkg)

    cmdline_file = constants.PACKAGE_INFO[test_options.package].cmdline_file
    self.flags = None
    if cmdline_file:
      self.flags = flag_changer.FlagChanger(self.device, cmdline_file)
    self._package = constants.PACKAGE_INFO[test_options.package].package
    self._activity = constants.PACKAGE_INFO[test_options.package].activity

  #override
  def InstallTestPackage(self):
    self.test_pkg.Install(self.device)

  #override
  def _RunTest(self, test, timeout):
    self.device.ClearApplicationState(self._package)
    if self.flags:
      annotations = self.test_pkg.GetTestAnnotations(test)
      if 'FirstRunExperience' == annotations.get('Feature', None):
        self.flags.RemoveFlags(['--disable-fre'])
      else:
        self.flags.AddFlags(['--disable-fre'])
    self.device.StartActivity(
        intent.Intent(action='android.intent.action.MAIN',
                      activity=self._activity,
                      package=self._package),
        blocking=True,
        force_stop=True)
    cmd = ['uiautomator', 'runtest',
           self.test_pkg.UIAUTOMATOR_PATH + self.test_pkg.GetPackageName(),
           '-e', 'class', test,
           '-e', 'test_package', self._package]
    return self.device.RunShellCommand(cmd, timeout=timeout, retries=0)

  #override
  def _GenerateTestResult(self, test, _result_code, _result_bundle, statuses,
                          start_ms, duration_ms):
    # uiautomator emits its summary status with INSTRUMENTATION_STATUS_CODE,
    # not INSTRUMENTATION_CODE, so we have to drop if off the list of statuses.
    summary_code, summary_bundle = statuses[-1]
    return super(TestRunner, self)._GenerateTestResult(
        test, summary_code, summary_bundle, statuses[:-1], start_ms,
        duration_ms)
