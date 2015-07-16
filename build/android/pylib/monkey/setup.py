# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Generates test runner factory and tests for monkey tests."""

from pylib.monkey import test_runner


def Setup(test_options):
  """Create and return the test runner factory and tests.

  Args:
    test_options: A MonkeyOptions object.

  Returns:
    A tuple of (TestRunnerFactory, tests).
  """
  # Token to replicate across devices as the "test". The TestRunner does all of
  # the work to run the test.
  tests = ['MonkeyTest']

  def TestRunnerFactory(device, shard_index):
    return test_runner.TestRunner(
        test_options, device, shard_index)

  return (TestRunnerFactory, tests)
