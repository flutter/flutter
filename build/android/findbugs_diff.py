#!/usr/bin/env python
#
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Runs findbugs, and returns an error code if there are new warnings.

Other options
  --only-analyze used to only analyze the class you are interested.
  --relase-build analyze the classes in out/Release directory.
  --findbugs-args used to passin other findbugs's options.

Run
  $CHROMIUM_SRC/third_party/findbugs/bin/findbugs -textui for details.

"""

import argparse
import os
import sys

from pylib import constants
from pylib.utils import findbugs

_DEFAULT_BASE_DIR = os.path.join(
    constants.DIR_SOURCE_ROOT, 'build', 'android', 'findbugs_filter')

sys.path.append(
    os.path.join(constants.DIR_SOURCE_ROOT, 'build', 'android', 'gyp'))
from util import build_utils


def main():
  parser = argparse.ArgumentParser()

  parser.add_argument(
      '-a', '--auxclasspath', default=None, dest='auxclasspath',
      help='Set aux classpath for analysis.')
  parser.add_argument(
      '--auxclasspath-gyp', dest='auxclasspath_gyp',
      help='A gyp list containing the aux classpath for analysis')
  parser.add_argument(
      '-o', '--only-analyze', default=None,
      dest='only_analyze', help='Only analyze the given classes and packages.')
  parser.add_argument(
      '-e', '--exclude', default=None, dest='exclude',
      help='Exclude bugs matching given filter.')
  parser.add_argument(
      '-l', '--release-build', action='store_true', dest='release_build',
      help='Analyze release build instead of debug.')
  parser.add_argument(
      '-f', '--findbug-args', default=None, dest='findbug_args',
      help='Additional findbug arguments.')
  parser.add_argument(
      '-b', '--base-dir', default=_DEFAULT_BASE_DIR,
      dest='base_dir', help='Base directory for configuration file.')
  parser.add_argument(
      '--output-file', dest='output_file',
      help='Path to save the output to.')
  parser.add_argument(
      '--stamp', help='Path to touch on success.')
  parser.add_argument(
      '--depfile', help='Path to the depfile. This must be specified as the '
                        "action's first output.")

  parser.add_argument(
      'jar_paths', metavar='JAR_PATH', nargs='+',
      help='JAR file to analyze')

  args = parser.parse_args(build_utils.ExpandFileArgs(sys.argv[1:]))
  if args.auxclasspath:
    args.auxclasspath = args.auxclasspath.split(':')
  elif args.auxclasspath_gyp:
    args.auxclasspath = build_utils.ParseGypList(args.auxclasspath_gyp)

  if args.base_dir:
    if not args.exclude:
      args.exclude = os.path.join(args.base_dir, 'findbugs_exclude.xml')

  findbugs_command, findbugs_warnings = findbugs.Run(
      args.exclude, args.only_analyze, args.auxclasspath,
      args.output_file, args.findbug_args, args.jar_paths)

  if findbugs_warnings:
    print
    print '*' * 80
    print 'FindBugs run via:'
    print findbugs_command
    print
    print 'FindBugs reported the following issues:'
    for warning in sorted(findbugs_warnings):
      print str(warning)
    print '*' * 80
    print
  else:
    if args.depfile:
      build_utils.WriteDepfile(
          args.depfile,
          build_utils.GetPythonDependencies() + args.auxclasspath
              + args.jar_paths)
    if args.stamp:
      build_utils.Touch(args.stamp)

  return len(findbugs_warnings)


if __name__ == '__main__':
  sys.exit(main())

