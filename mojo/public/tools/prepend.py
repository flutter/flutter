#!/usr/bin/env python
#
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Prepends a given file with a given line. This can be used to add a shebang line
to a generated file.
"""

import optparse
import os
import shutil
import sys


def main():
  parser = optparse.OptionParser()
  parser.add_option('--input', help='The file to prepend the line to.')
  parser.add_option('--line', help='The line to be prepended.')
  parser.add_option('--output', help='The output file.')

  options, _ = parser.parse_args()
  input_path = options.input
  output_path = options.output
  line = options.line

  # Warning - this reads all of the input file into memory.
  with open(output_path, 'w') as output_file:
    output_file.write(line + '\n')
    with open(input_path, 'r') as input_file:
      shutil.copyfileobj(input_file, output_file)


if __name__ == '__main__':
  sys.exit(main())
