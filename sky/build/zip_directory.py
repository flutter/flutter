#!/usr/bin/env python
#
# Copyright 2016 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

'''Zips up an entire directory.'''

import argparse
import shutil
import os

def main():
  parser = argparse.ArgumentParser(description=__doc__)

  parser.add_argument('--input-directory',
                      required=True,
                      dest='input_dir',
                      help='The input directory.')
  parser.add_argument('--output-archive',
                      required=True,
                      dest='output',
                      help='The path to the output archive.')

  args = parser.parse_args()

  input_dir = os.path.abspath(args.input_dir)
  output = os.path.abspath(args.output)

  if os.path.isfile(output):
    os.remove(output)

  temp_file = '%s' % output

  shutil.make_archive(
    temp_file,
    'zip',
    input_dir
  )

  shutil.move('%s.zip' % temp_file, output)


if __name__ == '__main__':
  main()
