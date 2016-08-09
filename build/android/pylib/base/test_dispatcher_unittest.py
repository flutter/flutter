#!/usr/bin/env python
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Unittests for test_dispatcher.py."""
# pylint: disable=R0201
# pylint: disable=W0212

import os
import sys
import unittest


from pylib import constants
from pylib.base import base_test_result
from pylib.base import test_collection
from pylib.base import test_dispatcher
from pylib.device import adb_wrapper
from pylib.device import device_utils
from pylib.utils import watchdog_timer

sys.path.append(
    os.path.join(constants.DIR_SOURCE_ROOT, 'third_party', 'pymock'))
import mock


class TestException(Exception):
  pass


def _MockDevice(serial):
  d = mock.MagicMock(spec=device_utils.DeviceUtils)
  d.__str__.return_value = serial
  d.adb = mock.MagicMock(spec=adb_wrapper.AdbWrapper)
  d.adb.GetDeviceSerial = mock.MagicMock(return_value=serial)
  d.IsOnline = mock.MagicMock(return_value=True)
  return d


class MockRunner(object):
  """A mock TestRunner."""
  def __init__(self, device=None, shard_index=0):
    self.device = device or _MockDevice('0')
    self.device_serial = self.device.adb.GetDeviceSerial()
    self.shard_index = shard_index
    self.setups = 0
    self.teardowns = 0

  def RunTest(self, test):
    results = base_test_result.TestRunResults()
    results.AddResult(
        base_test_result.BaseTestResult(test, base_test_result.ResultType.PASS))
    return (results, None)

  def SetUp(self):
    self.setups += 1

  def TearDown(self):
    self.teardowns += 1


class MockRunnerFail(MockRunner):
  def RunTest(self, test):
    results = base_test_result.TestRunResults()
    results.AddResult(
        base_test_result.BaseTestResult(test, base_test_result.ResultType.FAIL))
    return (results, test)


class MockRunnerFailTwice(MockRunner):
  def __init__(self, device=None, shard_index=0):
    super(MockRunnerFailTwice, self).__init__(device, shard_index)
    self._fails = 0

  def RunTest(self, test):
    self._fails += 1
    results = base_test_result.TestRunResults()
    if self._fails <= 2:
      results.AddResult(base_test_result.BaseTestResult(
          test, base_test_result.ResultType.FAIL))
      return (results, test)
    else:
      results.AddResult(base_test_result.BaseTestResult(
          test, base_test_result.ResultType.PASS))
      return (results, None)


class MockRunnerException(MockRunner):
  def RunTest(self, test):
    raise TestException


class TestFunctions(unittest.TestCase):
  """Tests test_dispatcher._RunTestsFromQueue."""
  @staticmethod
  def _RunTests(mock_runner, tests):
    results = []
    tests = test_collection.TestCollection(
        [test_dispatcher._Test(t) for t in tests])
    test_dispatcher._RunTestsFromQueue(mock_runner, tests, results,
                                       watchdog_timer.WatchdogTimer(None), 2)
    run_results = base_test_result.TestRunResults()
    for r in results:
      run_results.AddTestRunResults(r)
    return run_results

  def testRunTestsFromQueue(self):
    results = TestFunctions._RunTests(MockRunner(), ['a', 'b'])
    self.assertEqual(len(results.GetPass()), 2)
    self.assertEqual(len(results.GetNotPass()), 0)

  def testRunTestsFromQueueRetry(self):
    results = TestFunctions._RunTests(MockRunnerFail(), ['a', 'b'])
    self.assertEqual(len(results.GetPass()), 0)
    self.assertEqual(len(results.GetFail()), 2)

  def testRunTestsFromQueueFailTwice(self):
    results = TestFunctions._RunTests(MockRunnerFailTwice(), ['a', 'b'])
    self.assertEqual(len(results.GetPass()), 2)
    self.assertEqual(len(results.GetNotPass()), 0)

  def testSetUp(self):
    runners = []
    counter = test_dispatcher._ThreadSafeCounter()
    test_dispatcher._SetUp(MockRunner, _MockDevice('0'), runners, counter)
    self.assertEqual(len(runners), 1)
    self.assertEqual(runners[0].setups, 1)

  def testThreadSafeCounter(self):
    counter = test_dispatcher._ThreadSafeCounter()
    for i in xrange(5):
      self.assertEqual(counter.GetAndIncrement(), i)

  def testApplyMaxPerRun(self):
    self.assertEqual(
        ['A:B', 'C:D', 'E', 'F:G', 'H:I'],
        test_dispatcher.ApplyMaxPerRun(['A:B', 'C:D:E', 'F:G:H:I'], 2))


class TestThreadGroupFunctions(unittest.TestCase):
  """Tests test_dispatcher._RunAllTests and test_dispatcher._CreateRunners."""
  def setUp(self):
    self.tests = ['a', 'b', 'c', 'd', 'e', 'f', 'g']
    shared_test_collection = test_collection.TestCollection(
        [test_dispatcher._Test(t) for t in self.tests])
    self.test_collection_factory = lambda: shared_test_collection

  def testCreate(self):
    runners = test_dispatcher._CreateRunners(
        MockRunner, [_MockDevice('0'), _MockDevice('1')])
    for runner in runners:
      self.assertEqual(runner.setups, 1)
    self.assertEqual(set([r.device_serial for r in runners]),
                     set(['0', '1']))
    self.assertEqual(set([r.shard_index for r in runners]),
                     set([0, 1]))

  def testRun(self):
    runners = [MockRunner(_MockDevice('0')), MockRunner(_MockDevice('1'))]
    results, exit_code = test_dispatcher._RunAllTests(
        runners, self.test_collection_factory, 0)
    self.assertEqual(len(results.GetPass()), len(self.tests))
    self.assertEqual(exit_code, 0)

  def testTearDown(self):
    runners = [MockRunner(_MockDevice('0')), MockRunner(_MockDevice('1'))]
    test_dispatcher._TearDownRunners(runners)
    for runner in runners:
      self.assertEqual(runner.teardowns, 1)

  def testRetry(self):
    runners = test_dispatcher._CreateRunners(
        MockRunnerFail, [_MockDevice('0'), _MockDevice('1')])
    results, exit_code = test_dispatcher._RunAllTests(
        runners, self.test_collection_factory, 0)
    self.assertEqual(len(results.GetFail()), len(self.tests))
    self.assertEqual(exit_code, constants.ERROR_EXIT_CODE)

  def testReraise(self):
    runners = test_dispatcher._CreateRunners(
        MockRunnerException, [_MockDevice('0'), _MockDevice('1')])
    with self.assertRaises(TestException):
      test_dispatcher._RunAllTests(runners, self.test_collection_factory, 0)


class TestShard(unittest.TestCase):
  """Tests test_dispatcher.RunTests with sharding."""
  @staticmethod
  def _RunShard(runner_factory):
    return test_dispatcher.RunTests(
        ['a', 'b', 'c'], runner_factory, [_MockDevice('0'), _MockDevice('1')],
        shard=True)

  def testShard(self):
    results, exit_code = TestShard._RunShard(MockRunner)
    self.assertEqual(len(results.GetPass()), 3)
    self.assertEqual(exit_code, 0)

  def testFailing(self):
    results, exit_code = TestShard._RunShard(MockRunnerFail)
    self.assertEqual(len(results.GetPass()), 0)
    self.assertEqual(len(results.GetFail()), 3)
    self.assertEqual(exit_code, constants.ERROR_EXIT_CODE)

  def testNoTests(self):
    results, exit_code = test_dispatcher.RunTests(
        [], MockRunner, [_MockDevice('0'), _MockDevice('1')], shard=True)
    self.assertEqual(len(results.GetAll()), 0)
    self.assertEqual(exit_code, constants.ERROR_EXIT_CODE)


class TestReplicate(unittest.TestCase):
  """Tests test_dispatcher.RunTests with replication."""
  @staticmethod
  def _RunReplicate(runner_factory):
    return test_dispatcher.RunTests(
        ['a', 'b', 'c'], runner_factory, [_MockDevice('0'), _MockDevice('1')],
        shard=False)

  def testReplicate(self):
    results, exit_code = TestReplicate._RunReplicate(MockRunner)
    # We expect 6 results since each test should have been run on every device
    self.assertEqual(len(results.GetPass()), 6)
    self.assertEqual(exit_code, 0)

  def testFailing(self):
    results, exit_code = TestReplicate._RunReplicate(MockRunnerFail)
    self.assertEqual(len(results.GetPass()), 0)
    self.assertEqual(len(results.GetFail()), 6)
    self.assertEqual(exit_code, constants.ERROR_EXIT_CODE)

  def testNoTests(self):
    results, exit_code = test_dispatcher.RunTests(
        [], MockRunner, [_MockDevice('0'), _MockDevice('1')], shard=False)
    self.assertEqual(len(results.GetAll()), 0)
    self.assertEqual(exit_code, constants.ERROR_EXIT_CODE)


if __name__ == '__main__':
  unittest.main()
