# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Dispatches tests, either sharding or replicating them.

Performs the following steps:
* Create a test collection factory, using the given tests
  - If sharding: test collection factory returns the same shared test collection
    to all test runners
  - If replciating: test collection factory returns a unique test collection to
    each test runner, with the same set of tests in each.
* Create a test runner for each device.
* Run each test runner in its own thread, grabbing tests from the test
  collection until there are no tests left.
"""

# TODO(jbudorick) Deprecate and remove this class after any relevant parts have
# been ported to the new environment / test instance model.

import logging
import threading

from pylib import constants
from pylib.base import base_test_result
from pylib.base import test_collection
from pylib.device import device_errors
from pylib.utils import reraiser_thread
from pylib.utils import watchdog_timer


DEFAULT_TIMEOUT = 7 * 60  # seven minutes


class _ThreadSafeCounter(object):
  """A threadsafe counter."""

  def __init__(self):
    self._lock = threading.Lock()
    self._value = 0

  def GetAndIncrement(self):
    """Get the current value and increment it atomically.

    Returns:
      The value before incrementing.
    """
    with self._lock:
      pre_increment = self._value
      self._value += 1
      return pre_increment


class _Test(object):
  """Holds a test with additional metadata."""

  def __init__(self, test, tries=0):
    """Initializes the _Test object.

    Args:
      test: The test.
      tries: Number of tries so far.
    """
    self.test = test
    self.tries = tries


def _RunTestsFromQueue(runner, collection, out_results, watcher,
                       num_retries, tag_results_with_device=False):
  """Runs tests from the collection until empty using the given runner.

  Adds TestRunResults objects to the out_results list and may add tests to the
  out_retry list.

  Args:
    runner: A TestRunner object used to run the tests.
    collection: A TestCollection from which to get _Test objects to run.
    out_results: A list to add TestRunResults to.
    watcher: A watchdog_timer.WatchdogTimer object, used as a shared timeout.
    num_retries: Number of retries for a test.
    tag_results_with_device: If True, appends the name of the device on which
        the test was run to the test name. Used when replicating to identify
        which device ran each copy of the test, and to ensure each copy of the
        test is recorded separately.
  """

  def TagTestRunResults(test_run_results):
    """Tags all results with the last 4 digits of the device id.

    Used when replicating tests to distinguish the same tests run on different
    devices. We use a set to store test results, so the hash (generated from
    name and tag) must be unique to be considered different results.
    """
    new_test_run_results = base_test_result.TestRunResults()
    for test_result in test_run_results.GetAll():
      test_result.SetName('%s_%s' % (runner.device_serial[-4:],
                                     test_result.GetName()))
      new_test_run_results.AddResult(test_result)
    return new_test_run_results

  for test in collection:
    watcher.Reset()
    try:
      if not runner.device.IsOnline():
        # Device is unresponsive, stop handling tests on this device.
        msg = 'Device %s is unresponsive.' % runner.device_serial
        logging.warning(msg)
        raise device_errors.DeviceUnreachableError(msg)
      result, retry = runner.RunTest(test.test)
      if tag_results_with_device:
        result = TagTestRunResults(result)
      test.tries += 1
      if retry and test.tries <= num_retries:
        # Retry non-passing results, only record passing results.
        pass_results = base_test_result.TestRunResults()
        pass_results.AddResults(result.GetPass())
        out_results.append(pass_results)
        logging.warning('Will retry test %s, try #%s.', retry, test.tries)
        collection.add(_Test(test=retry, tries=test.tries))
      else:
        # All tests passed or retry limit reached. Either way, record results.
        out_results.append(result)
    except:
      # An unhandleable exception, ensure tests get run by another device and
      # reraise this exception on the main thread.
      collection.add(test)
      raise
    finally:
      # Retries count as separate tasks so always mark the popped test as done.
      collection.test_completed()


def _SetUp(runner_factory, device, out_runners, threadsafe_counter):
  """Creates a test runner for each device and calls SetUp() in parallel.

  Note: if a device is unresponsive the corresponding TestRunner will not be
    added to out_runners.

  Args:
    runner_factory: Callable that takes a device and index and returns a
      TestRunner object.
    device: The device serial number to set up.
    out_runners: List to add the successfully set up TestRunner object.
    threadsafe_counter: A _ThreadSafeCounter object used to get shard indices.
  """
  try:
    index = threadsafe_counter.GetAndIncrement()
    logging.warning('Creating shard %s for device %s.', index, device)
    runner = runner_factory(device, index)
    runner.SetUp()
    out_runners.append(runner)
  except device_errors.DeviceUnreachableError as e:
    logging.warning('Failed to create shard for %s: [%s]', device, e)


def _RunAllTests(runners, test_collection_factory, num_retries, timeout=None,
                 tag_results_with_device=False):
  """Run all tests using the given TestRunners.

  Args:
    runners: A list of TestRunner objects.
    test_collection_factory: A callable to generate a TestCollection object for
        each test runner.
    num_retries: Number of retries for a test.
    timeout: Watchdog timeout in seconds.
    tag_results_with_device: If True, appends the name of the device on which
        the test was run to the test name. Used when replicating to identify
        which device ran each copy of the test, and to ensure each copy of the
        test is recorded separately.

  Returns:
    A tuple of (TestRunResults object, exit code)
  """
  logging.warning('Running tests with %s test runners.' % (len(runners)))
  results = []
  exit_code = 0
  run_results = base_test_result.TestRunResults()
  watcher = watchdog_timer.WatchdogTimer(timeout)
  test_collections = [test_collection_factory() for _ in runners]

  threads = [
      reraiser_thread.ReraiserThread(
          _RunTestsFromQueue,
          [r, tc, results, watcher, num_retries, tag_results_with_device],
          name=r.device_serial[-4:])
      for r, tc in zip(runners, test_collections)]

  workers = reraiser_thread.ReraiserThreadGroup(threads)
  workers.StartAll()

  # Catch DeviceUnreachableErrors and set a warning exit code
  try:
    workers.JoinAll(watcher)
  except device_errors.DeviceUnreachableError as e:
    logging.error(e)

  if not all((len(tc) == 0 for tc in test_collections)):
    logging.error('Only ran %d tests (all devices are likely offline).' %
                  len(results))
    for tc in test_collections:
      run_results.AddResults(base_test_result.BaseTestResult(
          t, base_test_result.ResultType.UNKNOWN) for t in tc.test_names())

  for r in results:
    run_results.AddTestRunResults(r)
  if not run_results.DidRunPass():
    exit_code = constants.ERROR_EXIT_CODE
  return (run_results, exit_code)


def _CreateRunners(runner_factory, devices, timeout=None):
  """Creates a test runner for each device and calls SetUp() in parallel.

  Note: if a device is unresponsive the corresponding TestRunner will not be
    included in the returned list.

  Args:
    runner_factory: Callable that takes a device and index and returns a
      TestRunner object.
    devices: List of device serial numbers as strings.
    timeout: Watchdog timeout in seconds, defaults to the default timeout.

  Returns:
    A list of TestRunner objects.
  """
  logging.warning('Creating %s test runners.' % len(devices))
  runners = []
  counter = _ThreadSafeCounter()
  threads = reraiser_thread.ReraiserThreadGroup(
      [reraiser_thread.ReraiserThread(_SetUp,
                                      [runner_factory, d, runners, counter],
                                      name=str(d)[-4:])
       for d in devices])
  threads.StartAll()
  threads.JoinAll(watchdog_timer.WatchdogTimer(timeout))
  return runners


def _TearDownRunners(runners, timeout=None):
  """Calls TearDown() for each test runner in parallel.

  Args:
    runners: A list of TestRunner objects.
    timeout: Watchdog timeout in seconds, defaults to the default timeout.
  """
  threads = reraiser_thread.ReraiserThreadGroup(
      [reraiser_thread.ReraiserThread(r.TearDown, name=r.device_serial[-4:])
       for r in runners])
  threads.StartAll()
  threads.JoinAll(watchdog_timer.WatchdogTimer(timeout))


def ApplyMaxPerRun(tests, max_per_run):
  """Rearrange the tests so that no group contains more than max_per_run tests.

  Args:
    tests:
    max_per_run:

  Returns:
    A list of tests with no more than max_per_run per run.
  """
  tests_expanded = []
  for test_group in tests:
    if type(test_group) != str:
      # Do not split test objects which are not strings.
      tests_expanded.append(test_group)
    else:
      test_split = test_group.split(':')
      for i in range(0, len(test_split), max_per_run):
        tests_expanded.append(':'.join(test_split[i:i+max_per_run]))
  return tests_expanded


def RunTests(tests, runner_factory, devices, shard=True,
             test_timeout=DEFAULT_TIMEOUT, setup_timeout=DEFAULT_TIMEOUT,
             num_retries=2, max_per_run=256):
  """Run all tests on attached devices, retrying tests that don't pass.

  Args:
    tests: List of tests to run.
    runner_factory: Callable that takes a device and index and returns a
        TestRunner object.
    devices: List of attached devices.
    shard: True if we should shard, False if we should replicate tests.
      - Sharding tests will distribute tests across all test runners through a
        shared test collection.
      - Replicating tests will copy all tests to each test runner through a
        unique test collection for each test runner.
    test_timeout: Watchdog timeout in seconds for running tests.
    setup_timeout: Watchdog timeout in seconds for creating and cleaning up
        test runners.
    num_retries: Number of retries for a test.
    max_per_run: Maximum number of tests to run in any group.

  Returns:
    A tuple of (base_test_result.TestRunResults object, exit code).
  """
  if not tests:
    logging.critical('No tests to run.')
    return (base_test_result.TestRunResults(), constants.ERROR_EXIT_CODE)

  tests_expanded = ApplyMaxPerRun(tests, max_per_run)
  if shard:
    # Generate a shared TestCollection object for all test runners, so they
    # draw from a common pool of tests.
    shared_test_collection = test_collection.TestCollection(
        [_Test(t) for t in tests_expanded])
    test_collection_factory = lambda: shared_test_collection
    tag_results_with_device = False
    log_string = 'sharded across devices'
  else:
    # Generate a unique TestCollection object for each test runner, but use
    # the same set of tests.
    test_collection_factory = lambda: test_collection.TestCollection(
        [_Test(t) for t in tests_expanded])
    tag_results_with_device = True
    log_string = 'replicated on each device'

  logging.info('Will run %d tests (%s): %s',
               len(tests_expanded), log_string, str(tests_expanded))
  runners = _CreateRunners(runner_factory, devices, setup_timeout)
  try:
    return _RunAllTests(runners, test_collection_factory,
                        num_retries, test_timeout, tag_results_with_device)
  finally:
    try:
      _TearDownRunners(runners, setup_timeout)
    except device_errors.DeviceUnreachableError as e:
      logging.warning('Device unresponsive during TearDown: [%s]', e)
    except Exception as e:
      logging.error('Unexpected exception caught during TearDown: %s' % str(e))
