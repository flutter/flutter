#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A test runner for application tests."""

import argparse
import logging
import sys

import devtools
devtools.add_lib_to_path()
from devtoolslib.android_shell import AndroidShell
from devtoolslib.linux_shell import LinuxShell
from devtoolslib.apptest_runner import run_apptests
from devtoolslib import shell_arguments

from mopy import gtest
from mopy.config import Config
from mopy.gn import ConfigForGNArgs, ParseGNConfig
from mopy.log import InitLogging
from mopy.paths import Paths


_logger = logging.getLogger()


def main():
  parser = argparse.ArgumentParser(description="A test runner for application "
                                               "tests.")

  parser.add_argument("--verbose", help="be verbose (multiple times for more)",
                      default=0, dest="verbose_count", action="count")
  parser.add_argument("test_list_file", type=file,
                      help="a file listing apptests to run")
  parser.add_argument("build_dir", type=str,
                      help="the build output directory")
  args = parser.parse_args()

  InitLogging(args.verbose_count)
  config = ConfigForGNArgs(ParseGNConfig(args.build_dir))
  paths = Paths(config)
  extra_args = []
  if config.target_os == Config.OS_ANDROID:
    shell = AndroidShell(paths.adb_path)
    device_status, error = shell.CheckDevice()
    if not device_status:
      print 'Device check failed: ' + error
      return 1
    shell.InstallApk(paths.target_mojo_shell_path)
    extra_args.extend(shell_arguments.ConfigureLocalOrigin(
        shell, paths.build_dir, fixed_port=True))
  else:
    shell = LinuxShell(paths.mojo_shell_path)

  gtest.set_color()

  test_list_globals = {"config": config}
  exec args.test_list_file in test_list_globals
  apptests_result = run_apptests(shell, extra_args, test_list_globals["tests"])
  return 0 if apptests_result else 1


if __name__ == '__main__':
  sys.exit(main())
