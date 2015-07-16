#!/usr/bin/env python
#
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Extracts a set of zip archives. """

import ast
import optparse
import os
import sys
import zipfile

def DoUnzip(inputs, output):
  if not os.path.exists(output):
    os.makedirs(output)
  for i in inputs:
    with zipfile.ZipFile(i) as zf:
      zf.extractall(output)


def main():
  parser = optparse.OptionParser()

  parser.add_option('--inputs', help='List of archives to extract.')
  parser.add_option('--output', help='Path to unzip the archives to.')
  parser.add_option('--timestamp', help='Path to a timestamp file.')

  options, _ = parser.parse_args()

  inputs = []
  if (options.inputs):
    inputs = ast.literal_eval(options.inputs)

  DoUnzip(inputs, options.output)

  if options.timestamp:
    if os.path.exists(options.timestamp):
      os.utime(options.timestamp, None)
    else:
      with open(options.timestamp, 'a'):
        pass

if __name__ == '__main__':
  sys.exit(main())
