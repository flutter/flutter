# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Runs linker tests on a particular device."""

import logging
import os.path
import sys
import traceback

from pylib import constants
from pylib.base import base_test_result
from pylib.base import base_test_runner
from pylib.linker import test_case
from pylib.utils import apk_helper


# Name of the Android package to install for this to work.
_PACKAGE_NAME = 'ChromiumLinkerTest'


class LinkerExceptionTestResult(base_test_result.BaseTestResult):
  """Test result corresponding to a python exception in a host-custom test."""

  def __init__(self, test_name, exc_info):
    """Constructs a LinkerExceptionTestResult object.

    Args:
      test_name: name of the test which raised an exception.
      exc_info: exception info, ostensibly from sys.exc_info().
    """
    exc_type, exc_value, exc_traceback = exc_info
    trace_info = ''.join(traceback.format_exception(exc_type, exc_value,
                                                    exc_traceback))
    log_msg = 'Exception:\n' + trace_info

    super(LinkerExceptionTestResult, self).__init__(
        test_name,
        base_test_result.ResultType.FAIL,
        log="%s %s" % (exc_type, log_msg))


class LinkerTestRunner(base_test_runner.BaseTestRunner):
  """Orchestrates running a set of linker tests.

  Any Python exceptions in the tests are caught and translated into a failed
  result, rather than being re-raised on the main thread.
  """

  #override
  def __init__(self, device, tool):
    """Creates a new LinkerTestRunner.

    Args:
      device: Attached android device.
      tool: Name of the Valgrind tool.
    """
    super(LinkerTestRunner, self).__init__(device, tool)

  #override
  def InstallTestPackage(self):
    apk_path = os.path.join(
        constants.GetOutDirectory(), 'apks', '%s.apk' % _PACKAGE_NAME)

    if not os.path.exists(apk_path):
      raise Exception('%s not found, please build it' % apk_path)

    self.device.Install(apk_path)

  #override
  def RunTest(self, test):
    """Sets up and runs a test case.

    Args:
      test: An object which is ostensibly a subclass of LinkerTestCaseBase.

    Returns:
      A TestRunResults object which contains the result produced by the test
      and, in the case of a failure, the test that should be retried.
    """

    assert isinstance(test, test_case.LinkerTestCaseBase)

    try:
      results = test.Run(self.device)
    except Exception:
      logging.exception('Caught exception while trying to run test: ' +
                        test.tagged_name)
      exc_info = sys.exc_info()
      results = base_test_result.TestRunResults()
      results.AddResult(LinkerExceptionTestResult(
          test.tagged_name, exc_info))

    if not results.DidRunPass():
      return results, test
    else:
      return results, None
