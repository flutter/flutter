#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
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
      description='Creates a FAT Mach binary')

  parser.add_argument('--path', action='append', dest='paths',
      default=[], help='The path to a Mach binary')
  parser.add_argument('--output', type=str)
  parser.add_argument('--stamp', type=str)

  args = parser.parse_args()

  cmd = [
    '/usr/bin/env',
    'xcrun',
    'lipo',
  ]

  cmd.extend(args.paths)

  cmd.extend([
    '-create',
    '-output',
    args.output,
  ])

  subprocess.check_call(cmd)

  MakeStamp(args.stamp)

if __name__ == '__main__':
  sys.exit(main())
