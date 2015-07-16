#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Create placeholder files.
"""

import optparse
import os
import sys

from util import build_utils

def main():
  parser = optparse.OptionParser()
  parser.add_option(
      '--dest-lib-dir',
      help='Destination directory to have placeholder files.')
  parser.add_option(
      '--stamp',
      help='Path to touch on success')

  options, args = parser.parse_args()

  for name in args:
    target_path = os.path.join(options.dest_lib_dir, name)
    build_utils.Touch(target_path)

  if options.stamp:
    build_utils.Touch(options.stamp)

if __name__ == '__main__':
  sys.exit(main())

