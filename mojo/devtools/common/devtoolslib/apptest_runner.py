# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""High-level apptest runner that runs all tests specified in a list.

The list of tests has to contain one dictionary per test to be run, in the
following form:

 {
   # Required URL for apptest.
   "test": "mojo:test_app_url",
   # Optional display name (otherwise the entry for "test" above is used).
   "name": "mojo:test_app_url (more details)",
   # Optional test type. Valid values:
   #   * "gtest" (default)
   #   * "gtest_isolated": like "gtest", but run with fixture isolation,
   #      i.e., each test in a fresh mojo_shell)
   #   * "dart".
   "type": "gtest",
   # Optional arguments for the apptest.
   "test-args": ["--an_arg", "another_arg"],
   # Optional arguments for the shell.
   "shell-args": ["--some-flag-for-the-shell", "--another-flag"],
 }

TODO(vtl|msw): Add a way of specifying data dependencies.
"""

import sys
import logging

from .apptest_dart import run_dart_apptest
from .apptest_gtest import run_gtest_apptest

_logger = logging.getLogger()


def run_apptests(shell, common_shell_args, test_list):
  """Runs the apptests specified in |test_list| using the given |shell|.

  Args:
    shell: Shell that will run the tests, see shell.py.
    common_shell_args: Arguments that will be passed to the shell on each run.
        These will be appended to the shell-args specified for individual tests.
    test_list: List of tests to be run in the format described in the
        docstring of this module.

  Returns:
    True iff all tests succeeded, False otherwise.
  """
  succeeded = True
  for test_dict in test_list:
    test = test_dict["test"]
    test_name = test_dict.get("name", test)
    test_type = test_dict.get("type", "gtest")
    test_args = test_dict.get("test-args", [])
    shell_args = test_dict.get("shell-args", []) + common_shell_args

    _logger.info("Will start: %s" % test_name)
    print "Running %s...." % test_name,
    sys.stdout.flush()

    if test_type == "dart":
      apptest_result = run_dart_apptest(shell, shell_args, test, test_args)
    elif test_type == "gtest":
      apptest_result = run_gtest_apptest(shell, shell_args, test, test_args,
                                         False)
    elif test_type == "gtest_isolated":
      apptest_result = run_gtest_apptest(shell, shell_args, test, test_args,
                                         True)
    else:
      apptest_result = False
      print "Unrecognized test type in %r" % test_dict

    print "Succeeded" if apptest_result else "Failed"
    _logger.info("Completed: %s" % test_name)
    if not apptest_result:
      succeeded = False
  return succeeded
