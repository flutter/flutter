# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

#
# Most of this file was ported over from Blink's
# webkitpy/layout_tests/layout_package/json_results_generator_unittest.py
#

import unittest
import json

from pylib.utils import json_results_generator


class JSONGeneratorTest(unittest.TestCase):

  def setUp(self):
    self.builder_name = 'DUMMY_BUILDER_NAME'
    self.build_name = 'DUMMY_BUILD_NAME'
    self.build_number = 'DUMMY_BUILDER_NUMBER'

    # For archived results.
    self._json = None
    self._num_runs = 0
    self._tests_set = set([])
    self._test_timings = {}
    self._failed_count_map = {}

    self._PASS_count = 0
    self._DISABLED_count = 0
    self._FLAKY_count = 0
    self._FAILS_count = 0
    self._fixable_count = 0

    self._orig_write_json = json_results_generator.WriteJSON

    # unused arguments ... pylint: disable=W0613
    def _WriteJSONStub(json_object, file_path, callback=None):
      pass

    json_results_generator.WriteJSON = _WriteJSONStub

  def tearDown(self):
    json_results_generator.WriteJSON = self._orig_write_json

  def _TestJSONGeneration(self, passed_tests_list, failed_tests_list):
    tests_set = set(passed_tests_list) | set(failed_tests_list)

    DISABLED_tests = set([t for t in tests_set
                          if t.startswith('DISABLED_')])
    FLAKY_tests = set([t for t in tests_set
                       if t.startswith('FLAKY_')])
    FAILS_tests = set([t for t in tests_set
                       if t.startswith('FAILS_')])
    PASS_tests = tests_set - (DISABLED_tests | FLAKY_tests | FAILS_tests)

    failed_tests = set(failed_tests_list) - DISABLED_tests
    failed_count_map = dict([(t, 1) for t in failed_tests])

    test_timings = {}
    i = 0
    for test in tests_set:
      test_timings[test] = float(self._num_runs * 100 + i)
      i += 1

    test_results_map = dict()
    for test in tests_set:
      test_results_map[test] = json_results_generator.TestResult(
          test, failed=(test in failed_tests),
          elapsed_time=test_timings[test])

    generator = json_results_generator.JSONResultsGeneratorBase(
        self.builder_name, self.build_name, self.build_number,
        '',
        None,   # don't fetch past json results archive
        test_results_map)

    failed_count_map = dict([(t, 1) for t in failed_tests])

    # Test incremental json results
    incremental_json = generator.GetJSON()
    self._VerifyJSONResults(
        tests_set,
        test_timings,
        failed_count_map,
        len(PASS_tests),
        len(DISABLED_tests),
        len(FLAKY_tests),
        len(DISABLED_tests | failed_tests),
        incremental_json,
        1)

    # We don't verify the results here, but at least we make sure the code
    # runs without errors.
    generator.GenerateJSONOutput()
    generator.GenerateTimesMSFile()

  def _VerifyJSONResults(self, tests_set, test_timings, failed_count_map,
                         PASS_count, DISABLED_count, FLAKY_count,
                         fixable_count, json_obj, num_runs):
    # Aliasing to a short name for better access to its constants.
    JRG = json_results_generator.JSONResultsGeneratorBase

    self.assertIn(JRG.VERSION_KEY, json_obj)
    self.assertIn(self.builder_name, json_obj)

    buildinfo = json_obj[self.builder_name]
    self.assertIn(JRG.FIXABLE, buildinfo)
    self.assertIn(JRG.TESTS, buildinfo)
    self.assertEqual(len(buildinfo[JRG.BUILD_NUMBERS]), num_runs)
    self.assertEqual(buildinfo[JRG.BUILD_NUMBERS][0], self.build_number)

    if tests_set or DISABLED_count:
      fixable = {}
      for fixable_items in buildinfo[JRG.FIXABLE]:
        for (result_type, count) in fixable_items.iteritems():
          if result_type in fixable:
            fixable[result_type] = fixable[result_type] + count
          else:
            fixable[result_type] = count

      if PASS_count:
        self.assertEqual(fixable[JRG.PASS_RESULT], PASS_count)
      else:
        self.assertTrue(JRG.PASS_RESULT not in fixable or
                        fixable[JRG.PASS_RESULT] == 0)
      if DISABLED_count:
        self.assertEqual(fixable[JRG.SKIP_RESULT], DISABLED_count)
      else:
        self.assertTrue(JRG.SKIP_RESULT not in fixable or
                        fixable[JRG.SKIP_RESULT] == 0)
      if FLAKY_count:
        self.assertEqual(fixable[JRG.FLAKY_RESULT], FLAKY_count)
      else:
        self.assertTrue(JRG.FLAKY_RESULT not in fixable or
                        fixable[JRG.FLAKY_RESULT] == 0)

    if failed_count_map:
      tests = buildinfo[JRG.TESTS]
      for test_name in failed_count_map.iterkeys():
        test = self._FindTestInTrie(test_name, tests)

        failed = 0
        for result in test[JRG.RESULTS]:
          if result[1] == JRG.FAIL_RESULT:
            failed += result[0]
        self.assertEqual(failed_count_map[test_name], failed)

        timing_count = 0
        for timings in test[JRG.TIMES]:
          if timings[1] == test_timings[test_name]:
            timing_count = timings[0]
        self.assertEqual(1, timing_count)

    if fixable_count:
      self.assertEqual(sum(buildinfo[JRG.FIXABLE_COUNT]), fixable_count)

  def _FindTestInTrie(self, path, trie):
    nodes = path.split('/')
    sub_trie = trie
    for node in nodes:
      self.assertIn(node, sub_trie)
      sub_trie = sub_trie[node]
    return sub_trie

  def testJSONGeneration(self):
    self._TestJSONGeneration([], [])
    self._TestJSONGeneration(['A1', 'B1'], [])
    self._TestJSONGeneration([], ['FAILS_A2', 'FAILS_B2'])
    self._TestJSONGeneration(['DISABLED_A3', 'DISABLED_B3'], [])
    self._TestJSONGeneration(['A4'], ['B4', 'FAILS_C4'])
    self._TestJSONGeneration(['DISABLED_C5', 'DISABLED_D5'], ['A5', 'B5'])
    self._TestJSONGeneration(
        ['A6', 'B6', 'FAILS_C6', 'DISABLED_E6', 'DISABLED_F6'],
        ['FAILS_D6'])

    # Generate JSON with the same test sets. (Both incremental results and
    # archived results must be updated appropriately.)
    self._TestJSONGeneration(
        ['A', 'FLAKY_B', 'DISABLED_C'],
        ['FAILS_D', 'FLAKY_E'])
    self._TestJSONGeneration(
        ['A', 'DISABLED_C', 'FLAKY_E'],
        ['FLAKY_B', 'FAILS_D'])
    self._TestJSONGeneration(
        ['FLAKY_B', 'DISABLED_C', 'FAILS_D'],
        ['A', 'FLAKY_E'])

  def testHierarchicalJSNGeneration(self):
    # FIXME: Re-work tests to be more comprehensible and comprehensive.
    self._TestJSONGeneration(['foo/A'], ['foo/B', 'bar/C'])

  def testTestTimingsTrie(self):
    individual_test_timings = []
    individual_test_timings.append(
        json_results_generator.TestResult(
            'foo/bar/baz.html',
            elapsed_time=1.2))
    individual_test_timings.append(
        json_results_generator.TestResult('bar.html', elapsed_time=0.0001))
    trie = json_results_generator.TestTimingsTrie(individual_test_timings)

    expected_trie = {
        'bar.html': 0,
        'foo': {
            'bar': {
                'baz.html': 1200,
            }
        }
    }

    self.assertEqual(json.dumps(trie), json.dumps(expected_trie))
