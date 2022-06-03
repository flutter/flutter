#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import subprocess
import sys
import os


def main():
  parser = argparse.ArgumentParser(
      description='Copies architecture-dependent gen_snapshot binaries to output dir'
  )

  parser.add_argument('--dst', type=str, required=True)
  parser.add_argument('--out-dir', type=str)
  parser.add_argument('--arch', type=str)

  args = parser.parse_args()

  subdir = ''
  if args.arch != 'x64':
    subdir = 'clang_x64'

  generate_gen_snapshot(
      os.path.join(args.out_dir, subdir),
      os.path.join(args.dst, 'gen_snapshot_%s' % args.arch)
  )


def generate_gen_snapshot(directory, destination):
  gen_snapshot_dir = os.path.join(directory, 'gen_snapshot')
  if not os.path.isfile(gen_snapshot_dir):
    print('Cannot find gen_snapshot at %s' % gen_snapshot_dir)
    sys.exit(1)

  subprocess.check_call([
      'xcrun', 'bitcode_strip', '-r', gen_snapshot_dir, '-o', destination
  ])


if __name__ == '__main__':
  sys.exit(main())
