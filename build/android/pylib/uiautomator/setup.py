# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Generates test runner factory and tests for uiautomator tests."""

import logging

from pylib.uiautomator import test_package
from pylib.uiautomator import test_runner


def Setup(test_options):
  """Runs uiautomator tests on connected device(s).

  Args:
    test_options: A UIAutomatorOptions object.

  Returns:
    A tuple of (TestRunnerFactory, tests).
  """
  test_pkg = test_package.TestPackage(test_options.uiautomator_jar,
                                      test_options.uiautomator_info_jar)
  tests = test_pkg.GetAllMatchingTests(test_options.annotations,
                                       test_options.exclude_annotations,
                                       test_options.test_filter)

  if not tests:
    logging.error('No uiautomator tests to run with current args.')

  def TestRunnerFactory(device, shard_index):
    return test_runner.TestRunner(
        test_options, device, shard_index, test_pkg)

  return (TestRunnerFactory, tests)
