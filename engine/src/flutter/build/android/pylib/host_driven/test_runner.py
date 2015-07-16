# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Runs host-driven tests on a particular device."""

import logging
import sys
import time
import traceback

from pylib.base import base_test_result
from pylib.base import base_test_runner
from pylib.host_driven import test_case
from pylib.instrumentation import test_result


class HostDrivenExceptionTestResult(test_result.InstrumentationTestResult):
  """Test result corresponding to a python exception in a host-driven test."""

  def __init__(self, test_name, start_date_ms, exc_info):
    """Constructs a HostDrivenExceptionTestResult object.

    Args:
      test_name: name of the test which raised an exception.
      start_date_ms: the starting time for the test.
      exc_info: exception info, ostensibly from sys.exc_info().
    """
    exc_type, exc_value, exc_traceback = exc_info
    trace_info = ''.join(traceback.format_exception(exc_type, exc_value,
                                                    exc_traceback))
    log_msg = 'Exception:\n' + trace_info
    duration_ms = (int(time.time()) * 1000) - start_date_ms

    super(HostDrivenExceptionTestResult, self).__init__(
        test_name,
        base_test_result.ResultType.FAIL,
        start_date_ms,
        duration_ms,
        log=str(exc_type) + ' ' + log_msg)


class HostDrivenTestRunner(base_test_runner.BaseTestRunner):
  """Orchestrates running a set of host-driven tests.

  Any Python exceptions in the tests are caught and translated into a failed
  result, rather than being re-raised on the main thread.
  """

  # TODO(jbudorick): Remove cleanup_test_files once it's no longer used.
  # pylint: disable=unused-argument
  #override
  def __init__(self, device, shard_index, tool, cleanup_test_files=None):
    """Creates a new HostDrivenTestRunner.

    Args:
      device: Attached android device.
      shard_index: Shard index.
      tool: Name of the Valgrind tool.
      cleanup_test_files: Deprecated.
    """

    super(HostDrivenTestRunner, self).__init__(device, tool)

    # The shard index affords the ability to create unique port numbers (e.g.
    # DEFAULT_PORT + shard_index) if the test so wishes.
    self.shard_index = shard_index

  # pylint: enable=unused-argument

  #override
  def RunTest(self, test):
    """Sets up and runs a test case.

    Args:
      test: An object which is ostensibly a subclass of HostDrivenTestCase.

    Returns:
      A TestRunResults object which contains the result produced by the test
      and, in the case of a failure, the test that should be retried.
    """

    assert isinstance(test, test_case.HostDrivenTestCase)

    start_date_ms = int(time.time()) * 1000
    exception_raised = False

    try:
      test.SetUp(self.device, self.shard_index)
    except Exception:
      logging.exception(
          'Caught exception while trying to run SetUp() for test: ' +
          test.tagged_name)
      # Tests whose SetUp() method has failed are likely to fail, or at least
      # yield invalid results.
      exc_info = sys.exc_info()
      results = base_test_result.TestRunResults()
      results.AddResult(HostDrivenExceptionTestResult(
          test.tagged_name, start_date_ms, exc_info))
      return results, test

    try:
      results = test.Run()
    except Exception:
      # Setting this lets TearDown() avoid stomping on our stack trace from
      # Run() should TearDown() also raise an exception.
      exception_raised = True
      logging.exception('Caught exception while trying to run test: ' +
                        test.tagged_name)
      exc_info = sys.exc_info()
      results = base_test_result.TestRunResults()
      results.AddResult(HostDrivenExceptionTestResult(
          test.tagged_name, start_date_ms, exc_info))

    try:
      test.TearDown()
    except Exception:
      logging.exception(
          'Caught exception while trying run TearDown() for test: ' +
          test.tagged_name)
      if not exception_raised:
        # Don't stomp the error during the test if TearDown blows up. This is a
        # trade-off: if the test fails, this will mask any problem with TearDown
        # until the test is fixed.
        exc_info = sys.exc_info()
        results = base_test_result.TestRunResults()
        results.AddResult(HostDrivenExceptionTestResult(
            test.tagged_name, start_date_ms, exc_info))

    if not results.DidRunPass():
      return results, test
    else:
      return results, None
