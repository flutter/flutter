# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Run specific test on specific environment."""

import logging
import os
import tempfile

from pylib import constants
from pylib.base import base_test_result
from pylib.remote.device import remote_device_test_run
from pylib.utils import apk_helper


class RemoteDeviceInstrumentationTestRun(
    remote_device_test_run.RemoteDeviceTestRun):
  """Run instrumentation tests on a remote device."""

  #override
  def TestPackage(self):
    return self._test_instance.test_package

  #override
  def _TriggerSetUp(self):
    """Set up the triggering of a test run."""
    logging.info('Triggering test run.')

    with tempfile.NamedTemporaryFile(suffix='.txt') as test_list_file:
      tests = self._test_instance.GetTests()
      logging.debug('preparing to run %d instrumentation tests remotely:',
                    len(tests))
      for t in tests:
        test_name = '%s#%s' % (t['class'], t['method'])
        logging.debug('  %s', test_name)
        test_list_file.write('%s\n' % test_name)
      test_list_file.flush()
      self._test_instance._data_deps.append(
          (os.path.abspath(test_list_file.name), None))

      env_vars = self._test_instance.GetDriverEnvironmentVars(
          test_list_file_path=test_list_file.name)
      env_vars.update(self._test_instance.GetHttpServerEnvironmentVars())

      logging.debug('extras:')
      for k, v in env_vars.iteritems():
        logging.debug('  %s: %s', k, v)

      self._AmInstrumentTestSetup(
          self._test_instance.apk_under_test,
          self._test_instance.driver_apk,
          self._test_instance.driver_name,
          environment_variables=env_vars,
          extra_apks=[self._test_instance.test_apk])

  #override
  def _ParseTestResults(self):
    logging.info('Parsing results from stdout.')
    r = base_test_result.TestRunResults()
    result_code, result_bundle, statuses = (
        self._test_instance.ParseAmInstrumentRawOutput(
            self._results['results']['output'].splitlines()))
    result = self._test_instance.GenerateTestResults(
        result_code, result_bundle, statuses, 0, 0)

    if isinstance(result, base_test_result.BaseTestResult):
      r.AddResult(result)
    elif isinstance(result, list):
      r.AddResults(result)
    else:
      raise Exception('Unexpected result type: %s' % type(result).__name__)

    return r
