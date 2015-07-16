#!/usr/bin/env python
#
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Add an entry into the manifest file of a jar file."""

import optparse
import os
import os.path
import sys
import shutil
import tempfile
import zipfile

def AddKey(input_jar, output, key, value):
  working_dir = tempfile.mkdtemp()
  extracted_dir = os.path.join(working_dir, 'extracted')
  try:
    with zipfile.ZipFile(input_jar) as zf:
      zf.extractall(extracted_dir)
    manifest_file = os.path.join(extracted_dir, 'META-INF', 'MANIFEST.MF')
    manifest_content = ''
    if os.path.isfile(manifest_file):
      with open(manifest_file, 'r') as f:
        manifest_content = f.read().strip()
        if len(manifest_content):
          manifest_content += '\n'
      os.unlink(manifest_file)
    manifest_content += '%s: %s\n' % (key, value)
    with open(manifest_file, 'w') as f:
      f.write(manifest_content)
    shutil.make_archive(os.path.join(working_dir, 'output'), 'zip',
                        extracted_dir, '.')
    shutil.move(os.path.join(working_dir, 'output.zip'), output)
  finally:
    shutil.rmtree(working_dir)


def main():
  parser = optparse.OptionParser()

  parser.add_option('--input', help='Name of the input jar.')
  parser.add_option('--output', help='Name of the output jar.')
  parser.add_option('--key', help='Name of the key to add to the manifest.')
  parser.add_option('--value', help='Name of the value to add to the manifest.')

  options, _ = parser.parse_args()
  AddKey(options.input, options.output, options.key, options.value)


if __name__ == '__main__':
  sys.exit(main())
