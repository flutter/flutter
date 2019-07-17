#!/usr/bin/env python
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys
import subprocess
import os
import argparse
import errno
import shutil

def GetGNFiles(directory):
  directory = os.path.abspath(directory)
  gn_files = []
  assert os.path.exists(directory), "Directory must exist %s" % directory
  for root, dirs, files in os.walk(directory):
    for file in files:
        if file.endswith(".gn") or file.endswith(".gni"):
          gn_files.append(os.path.join(root, file))
  return gn_files

def main():
  parser = argparse.ArgumentParser();

  parser.add_argument('--gn-binary', dest='gn_binary', required=True, type=str)
  parser.add_argument('--dry-run', dest='dry_run', required=True, type=bool)
  parser.add_argument('--root-directory', dest='root_directory', required=True, type=str)

  args = parser.parse_args()

  gn_binary = os.path.abspath(args.gn_binary)
  assert os.path.exists(gn_binary), "GN Binary must exist %s" % gn_binary

  gn_command = [ gn_binary, 'format']

  if args.dry_run:
    gn_command.append('--dry-run')


  for gn_file in GetGNFiles(args.root_directory):
    if subprocess.call(gn_command + [ gn_file ]) != 0:
      print "ERROR: '%s' is incorrectly formatted." % os.path.relpath(gn_file, args.root_directory)
      print "Format the same with 'gn format' using the 'gn' binary in //buildtools."
      print "Or, run ./ci/check_gn_format.py with '--dry-run false'"
      return -1

  return 0

if __name__ == '__main__':
  sys.exit(main())
