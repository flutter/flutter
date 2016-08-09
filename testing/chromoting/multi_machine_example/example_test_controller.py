#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The test controller for the chromoting localhost browser_tests.

This test uses the legion framework to setup this controller which will run
the chromoting_integration_tests on a task machine. This is intended to be an
example Legion-based test for the chromoting team.

The controller will start a task machine to run browser_tests_launcher on. The
output of these tests are streamed back to the test controller to be output
on the controller's stdout and stderr channels. The final test output is then
read and becomes the final output of the controller, mirroring the test's
pass/fail result.
"""

import argparse
import logging
import os
import sys
import time

# Map the legion directory so we can import the host controller.
SRC_DIR = os.path.join('..', '..', '..')
sys.path.append(os.path.join(SRC_DIR, 'testing'))
from legion import test_controller


class ExampleController(test_controller.TestController):
  """The test controller for the Chromoting browser_tests."""

  def __init__(self):
    super(ExampleController, self).__init__()
    self.task = None
    self.args = None

  def RunTest(self):
    """Main method to run the test code."""
    self.ParseArgs()
    self.CreateTask()
    self.TestIntegrationTests()

  def CreateBrowserTestsLauncherCommand(self):
    return [
        'python',
        self.TaskAbsPath('../browser_tests_launcher.py'),
        '--commands_file', self.TaskAbsPath(self.args.commands_file),
        '--prod_dir', self.TaskAbsPath(self.args.prod_dir),
        '--cfg_file', self.TaskAbsPath(self.args.cfg_file),
        '--me2me_manifest_file', self.TaskAbsPath(
            self.args.me2me_manifest_file),
        '--it2me_manifest_file', self.TaskAbsPath(
            self.args.it2me_manifest_file),
        '--user_profile_dir', self.args.user_profile_dir,
        ]

  def TaskAbsPath(self, path):
    """Returns the absolute path to the resource on the task machine.

    Args:
      path: The relative path to the resource.

    Since the test controller and the task machines run in different tmp dirs
    on different machines the absolute path cannot be calculated correctly on
    this machine. This function maps the relative path (from this directory)
    to an absolute path on the task machine.
    """
    return self.task.rpc.AbsPath(path)

  def CreateTask(self):
    """Creates a task object and sets the proper values."""
    self.task = self.CreateNewTask(
        isolated_hash=self.args.task_machine,
        dimensions={'os': 'Ubuntu-14.04', 'pool': 'Chromoting'})
    self.task.Create()
    self.task.WaitForConnection()

  def ParseArgs(self):
    """Gets the command line args."""
    parser = argparse.ArgumentParser()
    parser.add_argument('--task_machine',
                        help='isolated hash of the task machine.')
    # The rest of the args are taken from
    # testing/chromoting/browser_tests_launcher.py.
    parser.add_argument('-f', '--commands_file',
                        help='path to file listing commands to be launched.')
    parser.add_argument('-p', '--prod_dir',
                        help='path to folder having product and test binaries.')
    parser.add_argument('-c', '--cfg_file',
                        help='path to test host config file.')
    parser.add_argument('--me2me_manifest_file',
                        help='path to me2me host manifest file.')
    parser.add_argument('--it2me_manifest_file',
                        help='path to it2me host manifest file.')
    parser.add_argument(
        '-u', '--user_profile_dir',
        help='path to user-profile-dir, used by connect-to-host tests.')
    self.args, _ = parser.parse_known_args()

  def TestIntegrationTests(self):
    """Runs the integration tests via browser_tests_launcher.py."""
    # Create a process object, configure it, and start it.
    # All interactions with the process are based on this "proc" key.
    proc = self.task.rpc.subprocess.Process(
        self.CreateBrowserTestsLauncherCommand())
    # Set the cwd to browser_tests_launcher relative to this directory.
    # This allows browser_test_launcher to use relative paths.
    self.task.rpc.subprocess.SetCwd(proc, '../')
    # Set the task verbosity to true to allow stdout/stderr to be echo'ed to
    # run_task's stdout/stderr on the task machine. This can assist in
    # debugging.
    self.task.rpc.subprocess.SetVerbose(proc)
    # Set the process as detached to create it in a new process group.
    self.task.rpc.subprocess.SetDetached(proc)
    # Start the actual process on the task machine.
    self.task.rpc.subprocess.Start(proc)

    # Collect the stdout/stderr and emit it from this controller while the
    # process is running.
    while self.task.rpc.subprocess.Poll(proc) is None:
      # Output the test's stdout and stderr in semi-realtime.
      # This is not true realtime due to the RPC calls and the 1s sleep.
      stdout, stderr = self.task.rpc.subprocess.ReadOutput(proc)
      if stdout:
        sys.stdout.write(stdout)
      if stderr:
        sys.stderr.write(stderr)
      time.sleep(1)

    # Get the return code, clean up the process object.
    returncode = self.task.rpc.subprocess.GetReturncode(proc)
    self.task.rpc.subprocess.Delete(proc)

    # Pass or fail depending on the return code from the browser_tests_launcher.
    if returncode != 0:
      raise AssertionError('browser_tests_launcher failed with return code '
                           '%i' % returncode)


if __name__ == '__main__':
  ExampleController().RunController()
