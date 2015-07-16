# Copyright (c) 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


"""Utility script to launch browser-tests on the Chromoting bot."""
import argparse
import glob
import hashlib
import os
from os.path import expanduser
import shutil
import socket
import subprocess

import psutil

BROWSER_TEST_ID = 'browser_tests'
PROD_DIR_ID = '#PROD_DIR#'
HOST_HASH_VALUE = hashlib.md5(socket.gethostname()).hexdigest()
SUCCESS_INDICATOR = 'SUCCESS: all tests passed.'
NATIVE_MESSAGING_DIR = 'NativeMessagingHosts'
CRD_ID = 'chrome-remote-desktop'  # Used in a few file/folder names
CHROMOTING_HOST_PATH = '/opt/google/chrome-remote-desktop/chrome-remote-desktop'
TEST_FAILURE = False
FAILING_TESTS = ''
HOST_READY_INDICATOR = 'Host ready to receive connections.'
BROWSER_NOT_STARTED_ERROR = (
    'Still waiting for the following processes to finish')
TIME_OUT_INDICATOR = '(TIMED OUT)'
MAX_RETRIES = 1


def LaunchBTCommand(args, command):
  """Launches the specified browser-test command.

      If the execution failed because a browser-instance was not launched, retry
      once.
  Args:
    args: Command line args, used for test-case startup tasks.
    command: Browser-test command line.
  """
  global TEST_FAILURE, FAILING_TESTS

  retries = 0
  while retries <= MAX_RETRIES:
    TestCaseSetup(args)
    results = RunCommandInSubProcess(command)

    if SUCCESS_INDICATOR in results:
      # Test passed.
      break

    # Sometimes, during execution of browser-tests, a browser instance is
    # not started and the test times out. See http://crbug/480025.
    # To work around it, check if this execution failed owing to that
    # problem and retry.
    # There are 2 things to look for in the results:
    # A line saying "Still waiting for the following processes to finish",
    # and, because sometimes that line gets logged even if the test
    # eventually passes, we'll also look for "(TIMED OUT)", before retrying.
    if not (
        BROWSER_NOT_STARTED_ERROR in results and TIME_OUT_INDICATOR in results):
      # Test failed for some other reason. Let's not retry.
      break
    retries += 1

  # Check that the test passed.
  if SUCCESS_INDICATOR not in results:
    TEST_FAILURE = True
    # Add this command-line to list of tests that failed.
    FAILING_TESTS += command


def RunCommandInSubProcess(command):
  """Creates a subprocess with command-line that is passed in.

  Args:
    command: The text of command to be executed.
  Returns:
    results: stdout contents of executing the command.
  """

  cmd_line = [command]
  try:
    results = subprocess.check_output(cmd_line, stderr=subprocess.STDOUT,
                                      shell=True)
  except subprocess.CalledProcessError, e:
    results = e.output
  finally:
    print results
  return results


def TestMachineCleanup(user_profile_dir):
  """Cleans up test machine so as not to impact other tests.

  Args:
    user_profile_dir: the user-profile folder used by Chromoting tests.

  """
  # Stop the host service.
  RunCommandInSubProcess(CHROMOTING_HOST_PATH + ' --stop')

  # Cleanup any host logs.
  RunCommandInSubProcess('rm /tmp/chrome_remote_desktop_*')

  # Remove the user-profile dir
  if os.path.exists(user_profile_dir):
    shutil.rmtree(user_profile_dir)


def InitialiseTestMachineForLinux(cfg_file):
  """Sets up a Linux machine for connect-to-host browser-tests.

  Copy over me2me host-config to expected locations.
  By default, the Linux me2me host expects the host-config file to be under
  $HOME/.config/chrome-remote-desktop
  Its name is expected to have a hash that is specific to a machine.

  Args:
    cfg_file: location of test account's host-config file.

  Raises:
    Exception: if host did not start properly.
  """

  # First get home directory on current machine.
  home_dir = expanduser('~')
  default_config_file_location = os.path.join(home_dir, '.config', CRD_ID)
  if os.path.exists(default_config_file_location):
    shutil.rmtree(default_config_file_location)
  os.makedirs(default_config_file_location)

  # Copy over test host-config to expected location, with expected file-name.
  # The file-name should contain a hash-value that is machine-specific.
  default_config_file_name = 'host#%s.json' % HOST_HASH_VALUE
  config_file_src = os.path.join(os.getcwd(), cfg_file)
  shutil.copyfile(
      config_file_src,
      os.path.join(default_config_file_location, default_config_file_name))

  # Make sure chromoting host is running.
  if not RestartMe2MeHost():
    # Host start failed. Don't run any tests.
    raise Exception('Host restart failed.')


def RestartMe2MeHost():
  """Stops and starts the Me2Me host on the test machine.

  Waits to confirm that host is ready to receive connections before returning.

  Returns:
    True: if HOST_READY_INDICATOR is found in stdout, indicating host is ready.
    False: if HOST_READY_INDICATOR not found in stdout.
  """

  # Stop chromoting host.
  RunCommandInSubProcess(CHROMOTING_HOST_PATH + ' --stop')
  # Start chromoting host.
  results = RunCommandInSubProcess(CHROMOTING_HOST_PATH + ' --start')
  # Confirm that the start process completed, and we got:
  # "Host ready to receive connections." in the log.
  if HOST_READY_INDICATOR not in results:
    return False
  return True


def SetupUserProfileDir(me2me_manifest_file, it2me_manifest_file,
                        user_profile_dir):
  """Sets up the Google Chrome user profile directory.

  Delete the previous user profile directory if exists and create a new one.
  This invalidates any state changes by the previous test so each test can start
  with the same environment.

  When a user launches the remoting web-app, the native messaging host process
  is started. For this to work, this function places the me2me and it2me native
  messaging host manifest files in a specific folder under the user-profile dir.

  Args:
    me2me_manifest_file: location of me2me native messaging host manifest file.
    it2me_manifest_file: location of it2me native messaging host manifest file.
    user_profile_dir: Chrome user-profile-directory.
  """
  native_messaging_folder = os.path.join(user_profile_dir, NATIVE_MESSAGING_DIR)

  if os.path.exists(user_profile_dir):
    shutil.rmtree(user_profile_dir)
  os.makedirs(native_messaging_folder)

  manifest_files = [me2me_manifest_file, it2me_manifest_file]
  for manifest_file in manifest_files:
    manifest_file_src = os.path.join(os.getcwd(), manifest_file)
    manifest_file_dest = (
        os.path.join(native_messaging_folder, os.path.basename(manifest_file)))
    shutil.copyfile(manifest_file_src, manifest_file_dest)


def PrintRunningProcesses():
  processes = psutil.get_process_list()
  processes = sorted(processes, key=lambda process: process.name)

  print 'List of running processes:\n'
  for process in processes:
    print process.name


def TestCaseSetup(args):
  # Stop+start me2me host process.
  if not RestartMe2MeHost():
    # Host restart failed. Don't run any more tests.
    raise Exception('Host restart failed.')

  # Reset the user profile directory to start each test with a clean slate.
  SetupUserProfileDir(args.me2me_manifest_file, args.it2me_manifest_file,
                      args.user_profile_dir)


def main(args):

  InitialiseTestMachineForLinux(args.cfg_file)

  with open(args.commands_file) as f:
    for line in f:
      # Replace the PROD_DIR value in the command-line with
      # the passed in value.
      line = line.replace(PROD_DIR_ID, args.prod_dir)
      # Launch specified command line for test.
      LaunchBTCommand(args, line)

  # All tests completed. Include host-logs in the test results.
  host_log_contents = ''
  # There should be only 1 log file, as we delete logs on test completion.
  # Loop through matching files, just in case there are more.
  for log_file in glob.glob('/tmp/chrome_remote_desktop_*'):
    with open(log_file, 'r') as log:
      host_log_contents += '\nHOST LOG %s\n CONTENTS:\n%s' % (
          log_file, log.read())
  print host_log_contents

  # Was there any test failure?
  if TEST_FAILURE:
    print '++++++++++AT LEAST 1 TEST FAILED++++++++++'
    print FAILING_TESTS.rstrip('\n')
    print '++++++++++++++++++++++++++++++++++++++++++'
    raise Exception('At least one test failed.')

if __name__ == '__main__':

  parser = argparse.ArgumentParser()
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
  command_line_args = parser.parse_args()
  try:
    main(command_line_args)
  finally:
    # Stop host and cleanup user-profile-dir.
    TestMachineCleanup(command_line_args.user_profile_dir)
