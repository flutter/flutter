#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A test runner for application tests."""

import argparse
import logging
import os.path
import subprocess
import sys

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
  parser.add_argument("test_list_file", type=str,
                      help="a file listing apptests to run")
  parser.add_argument("build_dir", type=str,
                      help="the build output directory")
  args = parser.parse_args()

  InitLogging(args.verbose_count)
  config = ConfigForGNArgs(ParseGNConfig(args.build_dir))
  paths = Paths(config)
  command_line = [os.path.join(os.path.dirname(__file__), os.path.pardir,
                               "devtools", "common", "mojo_test"),
                  str(args.test_list_file)]

  if config.target_os == Config.OS_ANDROID:
    command_line.append("--android")
    command_line.append("--adb-path=" + paths.adb_path)
    command_line.append("--origin=" + paths.build_dir)

  command_line.append("--shell-path=" + paths.target_mojo_shell_path)
  if args.verbose_count:
    command_line.append("--verbose")

  gtest.set_color()
  print "Running " + str(command_line)
  ret = subprocess.call(command_line)
  return ret


if __name__ == '__main__':
  sys.exit(main())
