#!/usr/bin/env python
#
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import optparse
import sys

from util import build_utils
from util import proguard_util

def DoProguard(options):
  proguard = proguard_util.ProguardCmdBuilder(options.proguard_path)
  proguard.injars(build_utils.ParseGypList(options.input_paths))
  proguard.configs(build_utils.ParseGypList(options.proguard_configs))
  proguard.outjar(options.output_path)

  if options.mapping:
    proguard.mapping(options.mapping)

  if options.is_test:
    proguard.is_test(True)

  classpath = []
  for arg in options.classpath:
    classpath += build_utils.ParseGypList(arg)
  classpath = list(set(classpath))
  proguard.libraryjars(classpath)

  proguard.CheckOutput()

  return proguard.GetInputs()


def main(args):
  args = build_utils.ExpandFileArgs(args)
  parser = optparse.OptionParser()
  build_utils.AddDepfileOption(parser)
  parser.add_option('--proguard-path',
                    help='Path to the proguard executable.')
  parser.add_option('--input-paths',
                    help='Paths to the .jar files proguard should run on.')
  parser.add_option('--output-path', help='Path to the generated .jar file.')
  parser.add_option('--proguard-configs',
                    help='Paths to proguard configuration files.')
  parser.add_option('--mapping', help='Path to proguard mapping to apply.')
  parser.add_option('--is-test', action='store_true',
      help='If true, extra proguard options for instrumentation tests will be '
      'added.')
  parser.add_option('--classpath', action='append',
                    help='Classpath for proguard.')
  parser.add_option('--stamp', help='Path to touch on success.')

  options, _ = parser.parse_args(args)

  inputs = DoProguard(options)

  if options.depfile:
    build_utils.WriteDepfile(
        options.depfile,
        inputs + build_utils.GetPythonDependencies())

  if options.stamp:
    build_utils.Touch(options.stamp)


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
