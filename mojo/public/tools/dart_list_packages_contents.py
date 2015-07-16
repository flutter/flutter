#!/usr/bin/python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""This script outputs the filenames of the files that are in the "packages/"
subdir of the given directory, relative to that directory."""

import argparse
import os
import sys

def main(target_directory, package_name):
  os.chdir(target_directory)
  self_path = 'packages/' + package_name
  for root, _, files in os.walk("packages", followlinks=True):
    for f in files:
      path = os.path.join(root, f)
      # Skip the contents of our own packages/package_name symlink.
      if not path.startswith(self_path):
        print os.path.join(root, f)

if __name__ == '__main__':
  parser = argparse.ArgumentParser(
      description="List filenames of files in the packages/ subdir of the "
                  "given directory.")
  parser.add_argument("--target-directory",
                      dest="target_directory",
                      metavar="<target-directory>",
                      type=str,
                      required=True,
                      help="The target directory, specified relative to this "
                           "directory.")
  parser.add_argument("--package-name",
                      dest="package_name",
                      metavar="<package-name>",
                      type=str,
                      required=True,
                      help="The name of the package whose packages/ is being "
                           "dumped.")
  args = parser.parse_args()
  sys.exit(main(args.target_directory, args.package_name))
