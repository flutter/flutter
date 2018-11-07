#!/usr/bin/env python
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import subprocess
import sys
import os


def MakeStamp(stamp_path):
  dir_name = os.path.dirname(stamp_path)

  if not os.path.isdir(dir_name):
    os.makedirs()

  with open(stamp_path, 'a'):
    os.utime(stamp_path, None)


def main():
  parser = argparse.ArgumentParser(
      description='Changes the install name of a dylib')

  parser.add_argument('--dylib', type=str)
  parser.add_argument('--install_name', type=str)
  parser.add_argument('--stamp', type=str)

  args = parser.parse_args()

  subprocess.check_call([
    '/usr/bin/env',
    'xcrun',
    'install_name_tool',
    '-id',
    args.install_name,
    args.dylib,
  ])

  MakeStamp(args.stamp)

if __name__ == '__main__':
  sys.exit(main())
