#!/usr/bin/env python
#
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""This finds the java distribution's tools.jar and copies it somewhere.
"""

import argparse
import os
import re
import shutil
import sys

from util import build_utils

RT_JAR_FINDER = re.compile(r'\[Opened (.*)/jre/lib/rt.jar\]')

def main():
  parser = argparse.ArgumentParser(description='Find Sun Tools Jar')
  parser.add_argument('--depfile',
                      help='Path to depfile. This must be specified as the '
                           'action\'s first output.')
  parser.add_argument('--output', required=True)
  args = parser.parse_args()

  sun_tools_jar_path = FindSunToolsJarPath()

  if sun_tools_jar_path is None:
    raise Exception("Couldn\'t find tools.jar")

  # Using copyfile instead of copy() because copy() calls copymode()
  # We don't want the locked mode because we may copy over this file again
  shutil.copyfile(sun_tools_jar_path, args.output)

  if args.depfile:
    build_utils.WriteDepfile(
        args.depfile,
        [sun_tools_jar_path] + build_utils.GetPythonDependencies())


def FindSunToolsJarPath():
  # This works with at least openjdk 1.6, 1.7 and sun java 1.6, 1.7
  stdout = build_utils.CheckOutput(
      ["java", "-verbose", "-version"], print_stderr=False)
  for ln in stdout.splitlines():
    match = RT_JAR_FINDER.match(ln)
    if match:
      return os.path.join(match.group(1), 'lib', 'tools.jar')

  return None


if __name__ == '__main__':
  sys.exit(main())
