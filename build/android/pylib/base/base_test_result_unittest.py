# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Unittests for TestRunResults."""

import unittest

from pylib.base.base_test_result import BaseTestResult
from pylib.base.base_test_result import TestRunResults
from pylib.base.base_test_result import ResultType


class TestTestRunResults(unittest.TestCase):
  def setUp(self):
    self.p1 = BaseTestResult('p1', ResultType.PASS, log='pass1')
    other_p1 = BaseTestResult('p1', ResultType.PASS)
    self.p2 = BaseTestResult('p2', ResultType.PASS)
    self.f1 = BaseTestResult('f1', ResultType.FAIL, log='failure1')
    self.c1 = BaseTestResult('c1', ResultType.CRASH, log='crash1')
    self.u1 = BaseTestResult('u1', ResultType.UNKNOWN)
    self.tr = TestRunResults()
    self.tr.AddResult(self.p1)
    self.tr.AddResult(other_p1)
    self.tr.AddResult(self.p2)
    self.tr.AddResults(set([self.f1, self.c1, self.u1]))

  def testGetAll(self):
    self.assertFalse(
        self.tr.GetAll().symmetric_difference(
            [self.p1, self.p2, self.f1, self.c1, self.u1]))

  def testGetPass(self):
    self.assertFalse(self.tr.GetPass().symmetric_difference(
        [self.p1, self.p2]))

  def testGetNotPass(self):
    self.assertFalse(self.tr.GetNotPass().symmetric_difference(
        [self.f1, self.c1, self.u1]))

  def testGetAddTestRunResults(self):
    tr2 = TestRunResults()
    other_p1 = BaseTestResult('p1', ResultType.PASS)
    f2 = BaseTestResult('f2', ResultType.FAIL)
    tr2.AddResult(other_p1)
    tr2.AddResult(f2)
    tr2.AddTestRunResults(self.tr)
    self.assertFalse(
        tr2.GetAll().symmetric_difference(
            [self.p1, self.p2, self.f1, self.c1, self.u1, f2]))

  def testGetLogs(self):
    log_print = ('[FAIL] f1:\n'
                 'failure1\n'
                 '[CRASH] c1:\n'
                 'crash1')
    self.assertEqual(self.tr.GetLogs(), log_print)

  def testGetShortForm(self):
    short_print = ('ALL: 5         PASS: 2        FAIL: 1        '
                   'CRASH: 1       TIMEOUT: 0     UNKNOWN: 1     ')
    self.assertEqual(self.tr.GetShortForm(), short_print)

  def testGetGtestForm(self):
    gtest_print = ('[==========] 5 tests ran.\n'
                   '[  PASSED  ] 2 tests.\n'
                   '[  FAILED  ] 3 tests, listed below:\n'
                   '[  FAILED  ] f1\n'
                   '[  FAILED  ] c1 (CRASHED)\n'
                   '[  FAILED  ] u1 (UNKNOWN)\n'
                   '\n'
                   '3 FAILED TESTS')
    self.assertEqual(gtest_print, self.tr.GetGtestForm())

  def testRunPassed(self):
    self.assertFalse(self.tr.DidRunPass())
    tr2 = TestRunResults()
    self.assertTrue(tr2.DidRunPass())


if __name__ == '__main__':
  unittest.main()
