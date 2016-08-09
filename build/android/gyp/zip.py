#!/usr/bin/env python
#
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Archives a set of files.
"""

import optparse
import sys

from util import build_utils

def main():
  parser = optparse.OptionParser()
  parser.add_option('--input-dir', help='Directory of files to archive.')
  parser.add_option('--output', help='Path to output archive.')
  options, _ = parser.parse_args()

  inputs = build_utils.FindInDirectory(options.input_dir, '*')
  build_utils.DoZip(inputs, options.output, options.input_dir)


if __name__ == '__main__':
  sys.exit(main())
