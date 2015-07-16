# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
This script writes a time stamp.
Has one argument - time stamp file. Usage:
python stamp.py path/to/file
"""

import sys

def WriteStampFile(stamp_file):
  with open(stamp_file, "w"):
    pass


def main(argv):
  stamp_file = argv[1]
  WriteStampFile(stamp_file)
  return 0

if __name__ == '__main__':
  sys.exit(main(sys.argv))
