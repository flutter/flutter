#!/usr/bin/env python
#
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Merges a list of jars into a single jar."""

import optparse
import sys

from util import build_utils

def main(args):
  args = build_utils.ExpandFileArgs(args)
  parser = optparse.OptionParser()
  build_utils.AddDepfileOption(parser)
  parser.add_option('--output', help='Path to output jar.')
  parser.add_option('--inputs', action='append', help='List of jar inputs.')
  options, _ = parser.parse_args(args)
  build_utils.CheckOptions(options, parser, ['output', 'inputs'])

  input_jars = []
  for inputs_arg in options.inputs:
    input_jars.extend(build_utils.ParseGypList(inputs_arg))

  build_utils.MergeZips(options.output, input_jars)

  if options.depfile:
    build_utils.WriteDepfile(
        options.depfile,
        input_jars + build_utils.GetPythonDependencies())


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
