#!/usr/bin/env python
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import subprocess
import sys
import os


def main():
  parser = argparse.ArgumentParser(
      description='Changes the install name of a dylib')

  parser.add_argument('--dylib', type=str)
  parser.add_argument('--install_name', type=str)
  # install_name_tool operates in place, which can't be expressed in GN, so
  # this tool copies to a new location first, then operates on the copy.
  parser.add_argument('--output', type=str)

  args = parser.parse_args()

  subprocess.check_call([
    '/usr/bin/env',
    'cp',
    '-fp',
    args.dylib,
    args.output,
  ])

  subprocess.check_call([
    '/usr/bin/env',
    'xcrun',
    'install_name_tool',
    '-id',
    args.install_name,
    args.output,
  ])

if __name__ == '__main__':
  sys.exit(main())
