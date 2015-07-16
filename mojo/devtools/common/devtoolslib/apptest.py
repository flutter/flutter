# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Apptest is a Mojo application that interacts with another Mojo application
and verifies assumptions about behavior of the app being tested.
"""

import logging
import time


_logger = logging.getLogger()


def _build_shell_arguments(shell_args, apptest_url, apptest_args):
  """Builds the list of arguments for the shell.

  Args:
    shell_args: List of arguments for the shell run.
    apptest_url: Url of the apptest app to run.
    apptest_args: Parameters to be passed to the apptest app.

  Returns:
    Single list of shell arguments.
  """
  result = list(shell_args)
  if apptest_args:
    result.append("--args-for=%s %s" % (apptest_url, " ".join(apptest_args)))
  result.append(apptest_url)
  return result


def run_apptest(shell, shell_args, apptest_url, apptest_args, output_test):
  """Runs shell with the given arguments, retrieves the output and applies
  |output_test| to determine if the run was successful.

  Args:
    shell: Wrapper around concrete Mojo shell, implementing devtools Shell
        interface.
    shell_args: List of arguments for the shell run.
    apptest_url: Url of the apptest app to run.
    apptest_args: Parameters to be passed to the apptest app.
    output_test: Function accepting the shell output and returning True iff
        the output indicates a successful run.

  Returns:
    True iff the test succeeded, False otherwise.
  """
  arguments = _build_shell_arguments(shell_args, apptest_url, apptest_args)
  command_line = "mojo_shell " + " ".join(["%r" % x for x in arguments])

  _logger.debug("Starting: " + command_line)
  start_time = time.time()
  (exit_code, output) = shell.RunAndGetOutput(arguments)
  run_time = time.time() - start_time
  _logger.debug("Completed: " + command_line)

  # Only log if it took more than 3 second.
  if run_time >= 3:
    _logger.info("Test took %.3f seconds: %s" % (run_time, command_line))

  if exit_code or not output_test(output):
    print 'Failed test: %r' % command_line
    if exit_code:
      print '  due to shell exit code %d' % exit_code
    else:
      print '  due to test results'
    print 72 * '-'
    print output
    print 72 * '-'
    return False
  return True
