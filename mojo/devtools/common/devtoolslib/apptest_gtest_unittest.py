# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import imp
import os.path
import sys
import unittest

try:
  imp.find_module("devtoolslib")
except ImportError:
  sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from devtoolslib.apptest_gtest import _gtest_list_tests


class GTestListTestsTest(unittest.TestCase):
  """Tests |_gtest_list_tests()| handling of --gtest_list_tests output."""

  def testSingleSuiteAndFixture(self):
    """Tests a single suite with a single fixture."""
    gtest_output = "TestSuite.\n  TestFixture\n"
    expected_test_list = ["TestSuite.TestFixture"]
    self.assertEquals(_gtest_list_tests(gtest_output), expected_test_list)

  def testWindowsNewlines(self):
    """Tests handling of \r\n newlines."""
    gtest_output = "TestSuite.\r\n  TestFixture1\r\n"
    expected_test_list = ["TestSuite.TestFixture1"]
    self.assertEquals(_gtest_list_tests(gtest_output), expected_test_list)

  def testSingleSuiteAndMultipleFixtures(self):
    """Tests a single suite with multiple fixtures."""
    gtest_output = "TestSuite.\n  TestFixture1\n  TestFixture2\n"
    expected_test_list = ["TestSuite.TestFixture1", "TestSuite.TestFixture2"]
    self.assertEquals(_gtest_list_tests(gtest_output), expected_test_list)

  def testMultipleSuitesAndFixtures(self):
    """Tests multiple suites each with multiple fixtures."""
    gtest_output = ("TestSuite1.\n  TestFixture1\n  TestFixture2\n"
                    "TestSuite2.\n  TestFixtureA\n  TestFixtureB\n")
    expected_test_list = ["TestSuite1.TestFixture1", "TestSuite1.TestFixture2",
                          "TestSuite2.TestFixtureA", "TestSuite2.TestFixtureB"]
    self.assertEquals(_gtest_list_tests(gtest_output), expected_test_list)

  def testUnrecognizedFormats(self):
    """Tests examples of unrecognized --gtest_list_tests output."""
    self.assertRaises(Exception, _gtest_list_tests, "Foo")
    self.assertRaises(Exception, _gtest_list_tests, "Foo\n")
    self.assertRaises(Exception, _gtest_list_tests, "Foo.Bar\n")
    self.assertRaises(Exception, _gtest_list_tests, "Foo.\nBar\n")
    self.assertRaises(Exception, _gtest_list_tests, "Foo.\r\nBar\r\nGaz\r\n")
    self.assertRaises(Exception, _gtest_list_tests, "Foo.\nBar.\n  Gaz\n")


if __name__ == "__main__":
  unittest.main()
