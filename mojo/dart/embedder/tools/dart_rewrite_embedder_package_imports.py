#!/usr/bin/python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script copies the source file to the destination file while rewriting
# "import 'package:....'" to "import 'embedder-package:....'"

import argparse
import os
import sys
import shutil

def main(args):
  parser = argparse.ArgumentParser(
      description='Rewrite all "package:" imports to "embedder-package:" '
                  'imports')
  parser.add_argument('source',
                      metavar='source',
                      help='Path to source file.')
  parser.add_argument('destination',
                      metavar='destination',
                      help='Path to destination file.')
  args = parser.parse_args()
  # Source file
  source = args.source
  # Destination file
  destination = args.destination
  # Create directory for destination file.
  try:
    os.makedirs(os.path.dirname(destination))
  except OSError:
    pass
  # Open source
  source_file = open(source, 'r')
  # Read source
  source_contents = source_file.read()
  source_file.close()
  # Rewrite source.
  source_contents = source_contents.replace(
      "import 'package:",
      "import 'dart:_")
  # Open destination
  destination_file = open(destination, 'w')
  # Write destination
  destination_file.write(source_contents)
  destination_file.close()

if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))

