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

def DoZip(inputs, link_inputs, zip_inputs, output, base_dir):
  files = []
  with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as outfile:
    for f in inputs:
      file_name = os.path.relpath(f, base_dir)
      files.append(file_name)
      outfile.write(f, file_name)
    for f in link_inputs:
      realf = os.path.realpath(f)  # Resolve symlinks.
      file_name = os.path.relpath(realf, base_dir)
      files.append(file_name)
      outfile.write(realf, file_name)
    for zf_name in zip_inputs:
      with zipfile.ZipFile(zf_name, 'r') as zf:
        for f in zf.namelist():
          if f not in files:
            files.append(f)
            with zf.open(f) as zff:
              outfile.writestr(f, zff.read())


def main():
  parser = optparse.OptionParser()

  parser.add_option('--inputs', help='List of files to archive.')
  parser.add_option('--link-inputs',
      help='List of files to archive. Symbolic links are resolved.')
  parser.add_option('--zip-inputs', help='List of zip files to re-archive.')
  parser.add_option('--output', help='Path to output archive.')
  parser.add_option('--base-dir',
                    help='If provided, the paths in the archive will be '
                    'relative to this directory', default='.')

  options, _ = parser.parse_args()

  inputs = []
  if (options.inputs):
    inputs = ast.literal_eval(options.inputs)
  link_inputs = []
  if options.link_inputs:
    link_inputs = ast.literal_eval(options.link_inputs)
  zip_inputs = []
  if options.zip_inputs:
    zip_inputs = ast.literal_eval(options.zip_inputs)
  output = options.output
  base_dir = options.base_dir

  DoZip(inputs, link_inputs, zip_inputs, output, base_dir)

if __name__ == '__main__':
  sys.exit(main())
