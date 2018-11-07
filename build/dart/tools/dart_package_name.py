#!/usr/bin/python
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""This script outputs the package name specified in the pubspec.yaml"""

import argparse
import os
import sys

# TODO(johnmccutchan): Use the yaml package to parse.
def PackageName(line):
  assert line.startswith("name:")
  return line.split(":")[1].strip()

def main(pubspec_file):
  source_file = open(pubspec_file, "r")
  for line in source_file:
    if line.startswith("name:"):
      print(PackageName(line))
      return 0
  source_file.close()
  # Couldn't find it.
  return -1

if __name__ == '__main__':
  parser = argparse.ArgumentParser(
      description="This script outputs the package name specified in the"
                  "pubspec.yaml")
  parser.add_argument("--pubspec",
                      dest="pubspec_file",
                      metavar="<pubspec-file>",
                      type=str,
                      required=True,
                      help="Path to pubspec file")
  args = parser.parse_args()
  sys.exit(main(args.pubspec_file))
