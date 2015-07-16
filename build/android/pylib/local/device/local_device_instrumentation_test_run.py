# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import logging
import re
import time

from pylib import flag_changer
from pylib.base import base_test_result
from pylib.base import test_run
from pylib.constants import keyevent
from pylib.device import device_errors
from pylib.local.device import local_device_test_run


TIMEOUT_ANNOTATIONS = [
  ('Manual', 10 * 60 * 60),
  ('IntegrationTest', 30 * 60),
  ('External', 10 * 60),
  ('EnormousTest', 10 * 60),
  ('LargeTest', 5 * 60),
  ('MediumTest', 3 * 60),
  ('SmallTest', 1 * 60),
]


# TODO(jbudorick): Make this private once the instrumentation test_runner is
# deprecated.
def DidPackageCrashOnDevice(package_name, device):
  # Dismiss any error dialogs. Limit the number in case we have an error
  # loop or we are failing to dismiss.
  try:
    for _ in xrange(10):
      package = _DismissCrashDialog(device)
      if not package:
        return False
      # Assume test package convention of ".test" suffix
      if package in package_name:
        return True
  except device_errors.CommandFailedError:
    logging.exception('Error while attempting to dismiss crash dialog.')
  return False


_CURRENT_FOCUS_CRASH_RE = re.compile(
    r'\s*mCurrentFocus.*Application (Error|Not Responding): (\S+)}')


def _DismissCrashDialog(device):
  # TODO(jbudorick): Try to grep the output on the device instead of using
  # large_output if/when DeviceUtils exposes a public interface for piped
  # shell command handling.
  for l in device.RunShellCommand(
      ['dumpsys', 'window', 'windows'], check_return=True, large_output=True):
    m = re.match(_CURRENT_FOCUS_CRASH_RE, l)
    if m:
      device.SendKeyEvent(keyevent.KEYCODE_DPAD_RIGHT)
      device.SendKeyEvent(keyevent.KEYCODE_DPAD_RIGHT)
      device.SendKeyEvent(keyevent.KEYCODE_ENTER)
      return m.group(2)

  return None


class LocalDeviceInstrumentationTestRun(
    local_device_test_run.LocalDeviceTestRun):
  def __init__(self, env, test_instance):
    super(LocalDeviceInstrumentationTestRun, self).__init__(env, test_instance)
    self._flag_changers = {}

  def TestPackage(self):
    return None

  def SetUp(self):
    def substitute_external_storage(d, external_storage):
      if not d:
        return external_storage
      elif isinstance(d, list):
        return '/'.join(p if p else external_storage for p in d)
      else:
        return d

    def individual_device_set_up(dev, host_device_tuples):
      dev.Install(self._test_instance.apk_under_test)
      dev.Install(self._test_instance.test_apk)

      external_storage = dev.GetExternalStoragePath()
      host_device_tuples = [
          (h, substitute_external_storage(d, external_storage))
          for h, d in host_device_tuples]
      logging.info('instrumentation data deps:')
      for h, d in host_device_tuples:
        logging.info('%r -> %r', h, d)
      dev.PushChangedFiles(host_device_tuples)
      if self._test_instance.flags:
        if not self._test_instance.package_info:
          logging.error("Couldn't set flags: no package info")
        elif not self._test_instance.package_info.cmdline_file:
          logging.error("Couldn't set flags: no cmdline_file")
        else:
          self._flag_changers[str(dev)] = flag_changer.FlagChanger(
              dev, self._test_instance.package_info.cmdline_file)
          logging.debug('Attempting to set flags: %r',
                        self._test_instance.flags)
          self._flag_changers[str(dev)].AddFlags(self._test_instance.flags)

    self._env.parallel_devices.pMap(
        individual_device_set_up,
        self._test_instance.GetDataDependencies())

  def TearDown(self):
    def individual_device_tear_down(dev):
      if str(dev) in self._flag_changers:
        self._flag_changers[str(dev)].Restore()

    self._env.parallel_devices.pMap(individual_device_tear_down)

  #override
  def _CreateShards(self, tests):
    return tests

  #override
  def _GetTests(self):
    return self._test_instance.GetTests()

  #override
  def _GetTestName(self, test):
    return '%s#%s' % (test['class'], test['method'])

  #override
  def _RunTest(self, device, test):
    extras = self._test_instance.GetHttpServerEnvironmentVars()

    if isinstance(test, list):
      if not self._test_instance.driver_apk:
        raise Exception('driver_apk does not exist. '
                        'Please build it and try again.')

      def name_and_timeout(t):
        n = self._GetTestName(t)
        i = self._GetTimeoutFromAnnotations(t['annotations'], n)
        return (n, i)

      test_names, timeouts = zip(*(name_and_timeout(t) for t in test))

      test_name = ','.join(test_names)
      target = '%s/%s' % (
          self._test_instance.driver_package,
          self._test_instance.driver_name)
      extras.update(
          self._test_instance.GetDriverEnvironmentVars(
              test_list=test_names))
      timeout = sum(timeouts)
    else:
      test_name = self._GetTestName(test)
      target = '%s/%s' % (
          self._test_instance.test_package, self._test_instance.test_runner)
      extras['class'] = test_name
      timeout = self._GetTimeoutFromAnnotations(test['annotations'], test_name)

    logging.info('preparing to run %s: %s' % (test_name, test))

    time_ms = lambda: int(time.time() * 1e3)
    start_ms = time_ms()
    output = device.StartInstrumentation(
        target, raw=True, extras=extras, timeout=timeout, retries=0)
    duration_ms = time_ms() - start_ms

    # TODO(jbudorick): Make instrumentation tests output a JSON so this
    # doesn't have to parse the output.
    logging.debug('output from %s:', test_name)
    for l in output:
      logging.debug('  %s', l)

    result_code, result_bundle, statuses = (
        self._test_instance.ParseAmInstrumentRawOutput(output))
    results = self._test_instance.GenerateTestResults(
        result_code, result_bundle, statuses, start_ms, duration_ms)
    if DidPackageCrashOnDevice(self._test_instance.test_package, device):
      for r in results:
        if r.GetType() == base_test_result.ResultType.UNKNOWN:
          r.SetType(base_test_result.ResultType.CRASH)
    return results

  #override
  def _ShouldShard(self):
    return True

  @staticmethod
  def _GetTimeoutFromAnnotations(annotations, test_name):
    for k, v in TIMEOUT_ANNOTATIONS:
      if k in annotations:
        timeout = v
    else:
      logging.warning('Using default 1 minute timeout for %s' % test_name)
      timeout = 60

    try:
      scale = int(annotations.get('TimeoutScale', 1))
    except ValueError as e:
      logging.warning("Non-integer value of TimeoutScale ignored. (%s)", str(e))
      scale = 1
    timeout *= scale

    return timeout

