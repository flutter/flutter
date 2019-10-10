#!/usr/bin/env python
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import zipfile
import os
import sys


def _zip_dir(path, zip_file, prefix):
  path = path.rstrip('/\\')
  for root, dirs, files in os.walk(path):
    for file in files:
      zip_file.write(os.path.join(root, file), os.path.join(
          root.replace(path, prefix), file))


def main(args):
  zip_file = zipfile.ZipFile(args.output, 'w', zipfile.ZIP_DEFLATED)
  for path, archive_name in args.input_pairs:
    if os.path.isdir(path):
      _zip_dir(path, zip_file, archive_name)
    else:
      zip_file.write(path, archive_name)
  zip_file.close()


if __name__ == '__main__':
  parser = argparse.ArgumentParser(
      description='This script creates zip files.')
  parser.add_argument('-o', dest='output', action='store',
      help='The name of the output zip file.')
  parser.add_argument('-i', dest='input_pairs', nargs=2, action='append',
      help='The input file and its destination location in the zip archive.')
  sys.exit(main(parser.parse_args()))
