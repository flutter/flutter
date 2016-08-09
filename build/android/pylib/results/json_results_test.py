#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import unittest

from pylib.base import base_test_result
from pylib.results import json_results


class JsonResultsTest(unittest.TestCase):

  def testGenerateResultsDict_passedResult(self):
    result = base_test_result.BaseTestResult(
        'test.package.TestName', base_test_result.ResultType.PASS)

    all_results = base_test_result.TestRunResults()
    all_results.AddResult(result)

    results_dict = json_results.GenerateResultsDict(all_results)
    self.assertEquals(
        ['test.package.TestName'],
        results_dict['all_tests'])
    self.assertEquals(1, len(results_dict['per_iteration_data']))

    iteration_result = results_dict['per_iteration_data'][0]
    self.assertTrue('test.package.TestName' in iteration_result)
    self.assertEquals(1, len(iteration_result['test.package.TestName']))

    test_iteration_result = iteration_result['test.package.TestName'][0]
    self.assertTrue('status' in test_iteration_result)
    self.assertEquals('SUCCESS', test_iteration_result['status'])

  def testGenerateResultsDict_skippedResult(self):
    result = base_test_result.BaseTestResult(
        'test.package.TestName', base_test_result.ResultType.SKIP)

    all_results = base_test_result.TestRunResults()
    all_results.AddResult(result)

    results_dict = json_results.GenerateResultsDict(all_results)
    self.assertEquals(
        ['test.package.TestName'],
        results_dict['all_tests'])
    self.assertEquals(1, len(results_dict['per_iteration_data']))

    iteration_result = results_dict['per_iteration_data'][0]
    self.assertTrue('test.package.TestName' in iteration_result)
    self.assertEquals(1, len(iteration_result['test.package.TestName']))

    test_iteration_result = iteration_result['test.package.TestName'][0]
    self.assertTrue('status' in test_iteration_result)
    self.assertEquals('SKIPPED', test_iteration_result['status'])

  def testGenerateResultsDict_failedResult(self):
    result = base_test_result.BaseTestResult(
        'test.package.TestName', base_test_result.ResultType.FAIL)

    all_results = base_test_result.TestRunResults()
    all_results.AddResult(result)

    results_dict = json_results.GenerateResultsDict(all_results)
    self.assertEquals(
        ['test.package.TestName'],
        results_dict['all_tests'])
    self.assertEquals(1, len(results_dict['per_iteration_data']))

    iteration_result = results_dict['per_iteration_data'][0]
    self.assertTrue('test.package.TestName' in iteration_result)
    self.assertEquals(1, len(iteration_result['test.package.TestName']))

    test_iteration_result = iteration_result['test.package.TestName'][0]
    self.assertTrue('status' in test_iteration_result)
    self.assertEquals('FAILURE', test_iteration_result['status'])

  def testGenerateResultsDict_duration(self):
    result = base_test_result.BaseTestResult(
        'test.package.TestName', base_test_result.ResultType.PASS, duration=123)

    all_results = base_test_result.TestRunResults()
    all_results.AddResult(result)

    results_dict = json_results.GenerateResultsDict(all_results)
    self.assertEquals(
        ['test.package.TestName'],
        results_dict['all_tests'])
    self.assertEquals(1, len(results_dict['per_iteration_data']))

    iteration_result = results_dict['per_iteration_data'][0]
    self.assertTrue('test.package.TestName' in iteration_result)
    self.assertEquals(1, len(iteration_result['test.package.TestName']))

    test_iteration_result = iteration_result['test.package.TestName'][0]
    self.assertTrue('elapsed_time_ms' in test_iteration_result)
    self.assertEquals(123, test_iteration_result['elapsed_time_ms'])

  def testGenerateResultsDict_multipleResults(self):
    result1 = base_test_result.BaseTestResult(
        'test.package.TestName1', base_test_result.ResultType.PASS)
    result2 = base_test_result.BaseTestResult(
        'test.package.TestName2', base_test_result.ResultType.PASS)

    all_results = base_test_result.TestRunResults()
    all_results.AddResult(result1)
    all_results.AddResult(result2)

    results_dict = json_results.GenerateResultsDict(all_results)
    self.assertEquals(
        ['test.package.TestName1', 'test.package.TestName2'],
        results_dict['all_tests'])
    self.assertEquals(2, len(results_dict['per_iteration_data']))

    expected_tests = set([
        'test.package.TestName1',
        'test.package.TestName2',
    ])

    for iteration_result in results_dict['per_iteration_data']:
      self.assertEquals(1, len(iteration_result))
      name = iteration_result.keys()[0]
      self.assertTrue(name in expected_tests)
      expected_tests.remove(name)
      self.assertEquals(1, len(iteration_result[name]))

      test_iteration_result = iteration_result[name][0]
      self.assertTrue('status' in test_iteration_result)
      self.assertEquals('SUCCESS', test_iteration_result['status'])


if __name__ == '__main__':
  unittest.main(verbosity=2)

