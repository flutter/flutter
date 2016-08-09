#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


"""Unit tests for instrumentation.TestRunner."""

# pylint: disable=W0212

import os
import sys
import unittest

from pylib import constants
from pylib.base import base_test_result
from pylib.instrumentation import instrumentation_test_instance

sys.path.append(os.path.join(
    constants.DIR_SOURCE_ROOT, 'third_party', 'pymock'))
import mock  # pylint: disable=F0401


class InstrumentationTestInstanceTest(unittest.TestCase):

  def setUp(self):
    options = mock.Mock()
    options.tool = ''

  def testGenerateTestResults_noStatus(self):
    results = instrumentation_test_instance.GenerateTestResults(
        None, None, [], 0, 1000)
    self.assertEqual([], results)

  def testGenerateTestResults_testPassed(self):
    statuses = [
      (1, {
        'class': 'test.package.TestClass',
        'test': 'testMethod',
      }),
      (0, {
        'class': 'test.package.TestClass',
        'test': 'testMethod',
      }),
    ]
    results = instrumentation_test_instance.GenerateTestResults(
        None, None, statuses, 0, 1000)
    self.assertEqual(1, len(results))
    self.assertEqual(base_test_result.ResultType.PASS, results[0].GetType())

  def testGenerateTestResults_testSkipped_true(self):
    statuses = [
      (1, {
        'class': 'test.package.TestClass',
        'test': 'testMethod',
      }),
      (0, {
        'test_skipped': 'true',
        'class': 'test.package.TestClass',
        'test': 'testMethod',
      }),
      (0, {
        'class': 'test.package.TestClass',
        'test': 'testMethod',
      }),
    ]
    results = instrumentation_test_instance.GenerateTestResults(
        None, None, statuses, 0, 1000)
    self.assertEqual(1, len(results))
    self.assertEqual(base_test_result.ResultType.SKIP, results[0].GetType())

  def testGenerateTestResults_testSkipped_false(self):
    statuses = [
      (1, {
        'class': 'test.package.TestClass',
        'test': 'testMethod',
      }),
      (0, {
        'test_skipped': 'false',
      }),
      (0, {
        'class': 'test.package.TestClass',
        'test': 'testMethod',
      }),
    ]
    results = instrumentation_test_instance.GenerateTestResults(
        None, None, statuses, 0, 1000)
    self.assertEqual(1, len(results))
    self.assertEqual(base_test_result.ResultType.PASS, results[0].GetType())

  def testGenerateTestResults_testFailed(self):
    statuses = [
      (1, {
        'class': 'test.package.TestClass',
        'test': 'testMethod',
      }),
      (-2, {
        'class': 'test.package.TestClass',
        'test': 'testMethod',
      }),
    ]
    results = instrumentation_test_instance.GenerateTestResults(
        None, None, statuses, 0, 1000)
    self.assertEqual(1, len(results))
    self.assertEqual(base_test_result.ResultType.FAIL, results[0].GetType())


if __name__ == '__main__':
  unittest.main(verbosity=2)
