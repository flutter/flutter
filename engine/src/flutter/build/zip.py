#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import json
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
  if args.source_file:
    with open(args.source_file) as source_file:
      file_dict_list = json.load(source_file)
      for file_dict in file_dict_list:
        if os.path.isdir(file_dict['source']):
          _zip_dir(file_dict['source'], zip_file, file_dict['destination'])
        else:
          zip_file.write(file_dict['source'], file_dict['destination'])
  else:
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
  parser.add_argument('-f', dest='source_file', action='store',
      help='The path to the file list to zip.')
  sys.exit(main(parser.parse_args()))
