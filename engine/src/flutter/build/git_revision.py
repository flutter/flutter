#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Get the Git HEAD revision of a specified Git repository."""




import sys
import subprocess
import os
import argparse

def GetRepositoryVersion(repository):
  "Returns the Git HEAD for the supplied repository path as a string."
  if not os.path.exists(repository):
    raise IOError("path doesn't exist")

  version = subprocess.check_output([
    'git',
    '-C',
    repository,
    'rev-parse',
    'HEAD',
  ])

  return str(version.strip(), 'utf-8')

def main():
  parser = argparse.ArgumentParser()

  parser.add_argument('--repository',
                      action='store',
                      help='Path to the Git repository.',
                      required=True)

  args = parser.parse_args()
  repository = os.path.abspath(args.repository)
  version = GetRepositoryVersion(repository)
  print(version.strip())

  return 0

if __name__ == '__main__':
  sys.exit(main())
