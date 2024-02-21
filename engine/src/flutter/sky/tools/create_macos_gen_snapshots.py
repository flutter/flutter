#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import subprocess
import sys
import os

buildroot_dir = os.path.abspath(os.path.join(os.path.realpath(__file__), '..', '..', '..', '..'))


def main():
  parser = argparse.ArgumentParser(
      description='Copies architecture-dependent gen_snapshot binaries to output dir'
  )

  parser.add_argument('--dst', type=str, required=True)
  parser.add_argument('--clang-dir', type=str, default='clang_x64')
  parser.add_argument('--x64-out-dir', type=str)
  parser.add_argument('--arm64-out-dir', type=str)
  parser.add_argument('--armv7-out-dir', type=str)
  parser.add_argument('--zip', action='store_true', default=False)

  args = parser.parse_args()

  dst = (args.dst if os.path.isabs(args.dst) else os.path.join(buildroot_dir, args.dst))

  # if dst folder does not exist create it.
  if not os.path.exists(dst):
    os.makedirs(dst)

  if args.x64_out_dir:
    x64_out_dir = (
        args.x64_out_dir
        if os.path.isabs(args.x64_out_dir) else os.path.join(buildroot_dir, args.x64_out_dir)
    )
    generate_gen_snapshot(x64_out_dir, os.path.join(dst, 'gen_snapshot_x64'))

  if args.arm64_out_dir:
    arm64_out_dir = (
        args.arm64_out_dir
        if os.path.isabs(args.arm64_out_dir) else os.path.join(buildroot_dir, args.arm64_out_dir)
    )
    generate_gen_snapshot(
        os.path.join(arm64_out_dir, args.clang_dir), os.path.join(dst, 'gen_snapshot_arm64')
    )

  if args.armv7_out_dir:
    armv7_out_dir = (
        args.armv7_out_dir
        if os.path.isabs(args.armv7_out_dir) else os.path.join(buildroot_dir, args.armv7_out_dir)
    )
    generate_gen_snapshot(
        os.path.join(armv7_out_dir, args.clang_dir), os.path.join(dst, 'gen_snapshot_armv7')
    )
  if args.zip:
    zip_archive(dst)


def embed_codesign_configuration(config_path, contents):
  with open(config_path, 'w') as file:
    file.write('\n'.join(contents) + '\n')


def zip_archive(dst):
  snapshot_filepath = ['gen_snapshot_arm64', 'gen_snapshot_x64']

  embed_codesign_configuration(os.path.join(dst, 'entitlements.txt'), snapshot_filepath)

  subprocess.check_call([
      'zip',
      '-r',
      'gen_snapshot.zip',
      '.',
  ], cwd=dst)


def generate_gen_snapshot(directory, destination):
  gen_snapshot_dir = os.path.join(directory, 'gen_snapshot')
  if not os.path.isfile(gen_snapshot_dir):
    print('Cannot find gen_snapshot at %s' % gen_snapshot_dir)
    sys.exit(1)

  subprocess.check_call(['xcrun', 'bitcode_strip', '-r', gen_snapshot_dir, '-o', destination])


if __name__ == '__main__':
  sys.exit(main())
