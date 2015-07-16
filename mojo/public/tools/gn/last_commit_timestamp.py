#!/usr/bin/env python
#
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Outputs the timestamp of the last commit in a Git repository."""

import argparse
import subprocess
import sys

def get_timestamp(directory):
  return subprocess.check_output(["git", "log", "-1", "--pretty=format:%ct"],
                                  cwd=directory)

def main():
  parser = argparse.ArgumentParser(description="Prints the timestamp of the "
                                   "last commit in a git repository")
  parser.add_argument("--directory", nargs='?',
                      help="Directory of the git repository", default=".")
  parser.add_argument("--output", nargs='?',
                      help="Output file, or stdout if omitted")
  args = parser.parse_args()

  output_file = sys.stdout
  if args.output:
    output_file = open(args.output, 'w')

  with output_file:
    # Print without newline so GN can read it.
    output_file.write(get_timestamp(args.directory))

if __name__ == '__main__':
  sys.exit(main())

