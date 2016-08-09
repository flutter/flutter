#!/usr/bin/env python
#
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Archives a set of files.
"""

import ast
import optparse
import os
import sys
import zipfile

sys.path.append(os.path.join(os.path.dirname(__file__), os.pardir, 'gyp'))
from util import build_utils

def DoZip(inputs, output, base_dir):
  with zipfile.ZipFile(output, 'w') as outfile:
    for f in inputs:
      outfile.write(f, os.path.relpath(f, base_dir))

def main():
  parser = optparse.OptionParser()
  build_utils.AddDepfileOption(parser)

  parser.add_option('--inputs', help='List of files to archive.')
  parser.add_option('--output', help='Path to output archive.')
  parser.add_option('--base-dir',
                    help='If provided, the paths in the archive will be '
                    'relative to this directory', default='.')

  options, _ = parser.parse_args()

  inputs = ast.literal_eval(options.inputs)
  output = options.output
  base_dir = options.base_dir

  DoZip(inputs, output, base_dir)

  if options.depfile:
    build_utils.WriteDepfile(
        options.depfile,
        build_utils.GetPythonDependencies())


if __name__ == '__main__':
  sys.exit(main())
