#!/usr/bin/env python
#
# Copyright 2018 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Get the Git HEAD revision of a specified Git repository."""

import sys
import subprocess
import os
import argparse

def main():
  parser = argparse.ArgumentParser();

  parser.add_argument('--repository',
                      action='store',
                      help='Path to the Git repository.',
                      required=True)

  args = parser.parse_args()

  repository = os.path.abspath(args.repository)

  if not os.path.exists(repository):
    exit -1

  version = subprocess.check_output([
    'git',
    '-C',
    repository,
    'rev-parse',
    '--short',
    'HEAD',
  ])

  print version.strip()

  return 0

if __name__ == '__main__':
  sys.exit(main())
