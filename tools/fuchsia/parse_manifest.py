#!/usr/bin/env python
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
""" Parses manifest file and dumps it to json.
"""

import argparse
import json
import os
import sys
import hashlib


def main():
  parser = argparse.ArgumentParser()

  parser.add_argument(
      '--input', dest='file_path', action='store', required=True)

  args = parser.parse_args()

  files = open(args.file_path, 'r')
  lines = files.read().split()

  output = {}

  for line in lines:
    key, val = line.strip().split('=')
    md5 = hashlib.md5(key.encode()).hexdigest()
    hash_key = 'md5_%s' % md5
    # Uncomment this line to get the hash keys
    # print val, hash_key
    output[hash_key] = os.path.dirname(val)

  print(json.dumps(output))

  return 0


if __name__ == '__main__':
  sys.exit(main())
