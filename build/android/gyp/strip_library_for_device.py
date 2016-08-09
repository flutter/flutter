#!/usr/bin/env python
#
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import optparse
import os
import sys

from util import build_utils


def StripLibrary(android_strip, android_strip_args, library_path, output_path):
  if build_utils.IsTimeStale(output_path, [library_path]):
    strip_cmd = ([android_strip] +
                 android_strip_args +
                 ['-o', output_path, library_path])
    build_utils.CheckOutput(strip_cmd)


def main(args):
  args = build_utils.ExpandFileArgs(args)

  parser = optparse.OptionParser()
  build_utils.AddDepfileOption(parser)

  parser.add_option('--android-strip',
      help='Path to the toolchain\'s strip binary')
  parser.add_option('--android-strip-arg', action='append',
      help='Argument to be passed to strip')
  parser.add_option('--libraries-dir',
      help='Directory for un-stripped libraries')
  parser.add_option('--stripped-libraries-dir',
      help='Directory for stripped libraries')
  parser.add_option('--libraries',
      help='List of libraries to strip')
  parser.add_option('--stamp', help='Path to touch on success')

  options, _ = parser.parse_args(args)

  libraries = build_utils.ParseGypList(options.libraries)

  build_utils.MakeDirectory(options.stripped_libraries_dir)

  for library in libraries:
    for base_path in options.libraries_dir.split(','):
      library_path = os.path.join(base_path, library)
      if (os.path.exists(library_path)):
        break
    stripped_library_path = os.path.join(
        options.stripped_libraries_dir, library)
    StripLibrary(options.android_strip, options.android_strip_arg, library_path,
        stripped_library_path)

  if options.stamp:
    build_utils.Touch(options.stamp)


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
