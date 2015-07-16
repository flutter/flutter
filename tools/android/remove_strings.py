#!/usr/bin/python
# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Remove strings by name from a GRD file."""

import optparse
import re
import sys


def RemoveStrings(grd_path, string_names):
  """Removes strings with the given names from a GRD file. Overwrites the file.

  Args:
    grd_path: path to the GRD file.
    string_names: a list of string names to be removed.
  """
  with open(grd_path, 'r') as f:
    grd = f.read()
  names_pattern = '|'.join(map(re.escape, string_names))
  pattern = r'<message [^>]*name="(%s)".*?</message>\s*' % names_pattern
  grd = re.sub(pattern, '', grd, flags=re.DOTALL)
  with open(grd_path, 'w') as f:
    f.write(grd)


def ParseArgs(args):
  usage = 'usage: %prog GRD_PATH...'
  parser = optparse.OptionParser(
      usage=usage, description='Remove strings from GRD files. Reads string '
      'names from stdin, and removes strings with those names from the listed '
      'GRD files.')
  options, args = parser.parse_args(args=args)
  if not args:
    parser.error('must provide GRD_PATH argument(s)')
  return args


def main(args=None):
  grd_paths = ParseArgs(args)
  strings_to_remove = filter(None, map(str.strip, sys.stdin.readlines()))
  for grd_path in grd_paths:
    RemoveStrings(grd_path, strings_to_remove)


if __name__ == '__main__':
  main()
