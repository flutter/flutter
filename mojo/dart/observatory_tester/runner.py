#!/usr/bin/python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""This script runs the Observatory tests in the mojo tree."""

import argparse
import os
import subprocess
import sys

MOJO_SHELL = 'mojo_shell'
TESTEE = 'mojo:observatory_test'

def main(build_dir, dart_exe, tester_script):
  shell_exe = os.path.join(build_dir, MOJO_SHELL)
  subprocess.check_call([
    dart_exe,
    tester_script,
    shell_exe,
    TESTEE
  ])

if __name__ == '__main__':
  parser = argparse.ArgumentParser(
      description="List filenames of files in the packages/ subdir of the "
                  "given directory.")
  parser.add_argument("--build-dir",
                      dest="build_dir",
                      metavar="<build-directory>",
                      type=str,
                      required=True,
                      help="The directory containing mojo_shell.")
  parser.add_argument("--dart-exe",
                      dest="dart_exe",
                      metavar="<package-name>",
                      type=str,
                      required=True,
                      help="Path to dart executable.")
  args = parser.parse_args()
  tester_dir = os.path.dirname(os.path.realpath(__file__))
  tester_dart_script = os.path.join(tester_dir, 'tester.dart');
  sys.exit(main(args.build_dir, args.dart_exe, tester_dart_script))
