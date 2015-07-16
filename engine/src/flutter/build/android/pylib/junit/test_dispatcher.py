# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

from pylib import constants
from pylib.base import base_test_result

def RunTests(tests, runner_factory):
  """Runs a set of java tests on the host.

  Return:
    A tuple containing the results & the exit code.
  """
  def run(t):
    runner = runner_factory(None, None)
    runner.SetUp()
    results_list, return_code = runner.RunTest(t)
    runner.TearDown()
    return (results_list, return_code == 0)

  test_run_results = base_test_result.TestRunResults()
  exit_code = 0
  for t in tests:
    results_list, passed = run(t)
    test_run_results.AddResults(results_list)
    if not passed:
      exit_code = constants.ERROR_EXIT_CODE
  return (test_run_results, exit_code)