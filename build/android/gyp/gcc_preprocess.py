#!/usr/bin/env python
#
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import optparse
import os
import sys

from util import build_utils

def DoGcc(options):
  build_utils.MakeDirectory(os.path.dirname(options.output))

  gcc_cmd = [ 'gcc' ]  # invoke host gcc.
  if options.defines:
    gcc_cmd.extend(sum(map(lambda w: ['-D', w], options.defines), []))
  gcc_cmd.extend([
      '-E',                  # stop after preprocessing.
      '-D', 'ANDROID',       # Specify ANDROID define for pre-processor.
      '-x', 'c-header',      # treat sources as C header files
      '-P',                  # disable line markers, i.e. '#line 309'
      '-I', options.include_path,
      '-o', options.output,
      options.template
      ])

  build_utils.CheckOutput(gcc_cmd)


def main(args):
  args = build_utils.ExpandFileArgs(args)

  parser = optparse.OptionParser()
  build_utils.AddDepfileOption(parser)

  parser.add_option('--include-path', help='Include path for gcc.')
  parser.add_option('--template', help='Path to template.')
  parser.add_option('--output', help='Path for generated file.')
  parser.add_option('--stamp', help='Path to touch on success.')
  parser.add_option('--defines', help='Pre-defines macros', action='append')

  options, _ = parser.parse_args(args)

  DoGcc(options)

  if options.depfile:
    build_utils.WriteDepfile(
        options.depfile,
        build_utils.GetPythonDependencies())

  if options.stamp:
    build_utils.Touch(options.stamp)


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
