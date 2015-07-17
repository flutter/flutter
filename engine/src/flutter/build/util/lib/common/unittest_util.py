# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Utilities for dealing with the python unittest module."""

import fnmatch
import sys
import unittest


class _TextTestResult(unittest._TextTestResult):
  """A test result class that can print formatted text results to a stream.

  Results printed in conformance with gtest output format, like:
  [ RUN        ] autofill.AutofillTest.testAutofillInvalid: "test desc."
  [         OK ] autofill.AutofillTest.testAutofillInvalid
  [ RUN        ] autofill.AutofillTest.testFillProfile: "test desc."
  [         OK ] autofill.AutofillTest.testFillProfile
  [ RUN        ] autofill.AutofillTest.testFillProfileCrazyCharacters: "Test."
  [         OK ] autofill.AutofillTest.testFillProfileCrazyCharacters
  """
  def __init__(self, stream, descriptions, verbosity):
    unittest._TextTestResult.__init__(self, stream, descriptions, verbosity)
    self._fails = set()

  def _GetTestURI(self, test):
    return '%s.%s.%s' % (test.__class__.__module__,
                         test.__class__.__name__,
                         test._testMethodName)

  def getDescription(self, test):
    return '%s: "%s"' % (self._GetTestURI(test), test.shortDescription())

  def startTest(self, test):
    unittest.TestResult.startTest(self, test)
    self.stream.writeln('[ RUN        ] %s' % self.getDescription(test))

  def addSuccess(self, test):
    unittest.TestResult.addSuccess(self, test)
    self.stream.writeln('[         OK ] %s' % self._GetTestURI(test))

  def addError(self, test, err):
    unittest.TestResult.addError(self, test, err)
    self.stream.writeln('[      ERROR ] %s' % self._GetTestURI(test))
    self._fails.add(self._GetTestURI(test))

  def addFailure(self, test, err):
    unittest.TestResult.addFailure(self, test, err)
    self.stream.writeln('[     FAILED ] %s' % self._GetTestURI(test))
    self._fails.add(self._GetTestURI(test))

  def getRetestFilter(self):
    return ':'.join(self._fails)


class TextTestRunner(unittest.TextTestRunner):
  """Test Runner for displaying test results in textual format.

  Results are displayed in conformance with google test output.
  """

  def __init__(self, verbosity=1):
    unittest.TextTestRunner.__init__(self, stream=sys.stderr,
                                     verbosity=verbosity)

  def _makeResult(self):
    return _TextTestResult(self.stream, self.descriptions, self.verbosity)


def GetTestsFromSuite(suite):
  """Returns all the tests from a given test suite."""
  tests = []
  for x in suite:
    if isinstance(x, unittest.TestSuite):
      tests += GetTestsFromSuite(x)
    else:
      tests += [x]
  return tests


def GetTestNamesFromSuite(suite):
  """Returns a list of every test name in the given suite."""
  return map(lambda x: GetTestName(x), GetTestsFromSuite(suite))


def GetTestName(test):
  """Gets the test name of the given unittest test."""
  return '.'.join([test.__class__.__module__,
                   test.__class__.__name__,
                   test._testMethodName])


def FilterTestSuite(suite, gtest_filter):
  """Returns a new filtered tests suite based on the given gtest filter.

  See http://code.google.com/p/googletest/wiki/AdvancedGuide
  for gtest_filter specification.
  """
  return unittest.TestSuite(FilterTests(GetTestsFromSuite(suite), gtest_filter))


def FilterTests(all_tests, gtest_filter):
  """Filter a list of tests based on the given gtest filter.

  Args:
    all_tests: List of tests (unittest.TestSuite)
    gtest_filter: Filter to apply.

  Returns:
    Filtered subset of the given list of tests.
  """
  test_names = [GetTestName(test) for test in all_tests]
  filtered_names = FilterTestNames(test_names, gtest_filter)
  return [test for test in all_tests if GetTestName(test) in filtered_names]


def FilterTestNames(all_tests, gtest_filter):
  """Filter a list of test names based on the given gtest filter.

  See http://code.google.com/p/googletest/wiki/AdvancedGuide
  for gtest_filter specification.

  Args:
    all_tests: List of test names.
    gtest_filter: Filter to apply.

  Returns:
    Filtered subset of the given list of test names.
  """
  pattern_groups = gtest_filter.split('-')
  positive_patterns = ['*']
  if pattern_groups[0]:
    positive_patterns = pattern_groups[0].split(':')
  negative_patterns = None
  if len(pattern_groups) > 1:
    negative_patterns = pattern_groups[1].split(':')

  tests = []
  for test in all_tests:
    # Test name must by matched by one positive pattern.
    for pattern in positive_patterns:
      if fnmatch.fnmatch(test, pattern):
        break
    else:
      continue
    # Test name must not be matched by any negative patterns.
    for pattern in negative_patterns or []:
      if fnmatch.fnmatch(test, pattern):
        break
    else:
      tests += [test]
  return tests
