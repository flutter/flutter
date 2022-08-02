#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import subprocess
import shutil
import sys
import os

from create_xcframework import create_xcframework

buildroot_dir = os.path.abspath(
    os.path.join(os.path.realpath(__file__), '..', '..', '..', '..')
)

DSYMUTIL = os.path.join(
    os.path.dirname(__file__), '..', '..', '..', 'buildtools', 'mac-x64',
    'clang', 'bin', 'dsymutil'
)

out_dir = os.path.join(buildroot_dir, 'out')


def main():
  parser = argparse.ArgumentParser(
      description='Creates FlutterMacOS.framework for macOS'
  )

  parser.add_argument('--dst', type=str, required=True)
  parser.add_argument('--arm64-out-dir', type=str, required=True)
  parser.add_argument('--x64-out-dir', type=str, required=True)
  parser.add_argument('--strip', action="store_true", default=False)
  parser.add_argument('--dsym', action="store_true", default=False)

  args = parser.parse_args()

  dst = (
      args.dst
      if os.path.isabs(args.dst) else os.path.join(buildroot_dir, args.dst)
  )
  arm64_out_dir = (
      args.arm64_out_dir if os.path.isabs(args.arm64_out_dir) else
      os.path.join(buildroot_dir, args.arm64_out_dir)
  )
  x64_out_dir = (
      args.x64_out_dir if os.path.isabs(args.x64_out_dir) else
      os.path.join(buildroot_dir, args.x64_out_dir)
  )

  fat_framework = os.path.join(dst, 'FlutterMacOS.framework')
  arm64_framework = os.path.join(arm64_out_dir, 'FlutterMacOS.framework')
  x64_framework = os.path.join(x64_out_dir, 'FlutterMacOS.framework')

  arm64_dylib = os.path.join(arm64_framework, 'FlutterMacOS')
  x64_dylib = os.path.join(x64_framework, 'FlutterMacOS')

  if not os.path.isdir(arm64_framework):
    print('Cannot find macOS arm64 Framework at %s' % arm64_framework)
    return 1

  if not os.path.isdir(x64_framework):
    print('Cannot find macOS x64 Framework at %s' % x64_framework)
    return 1

  if not os.path.isfile(arm64_dylib):
    print('Cannot find macOS arm64 dylib at %s' % arm64_dylib)
    return 1

  if not os.path.isfile(x64_dylib):
    print('Cannot find macOS x64 dylib at %s' % x64_dylib)
    return 1

  if not os.path.isfile(DSYMUTIL):
    print('Cannot find dsymutil at %s' % DSYMUTIL)
    return 1

  shutil.rmtree(fat_framework, True)
  shutil.copytree(arm64_framework, fat_framework, symlinks=True)

  fat_framework_binary = os.path.join(
      fat_framework, 'Versions', 'A', 'FlutterMacOS'
  )

  # Create the arm64/x64 fat framework.
  result = subprocess.run([
      'lipo', arm64_dylib, x64_dylib, '-create', '-output', fat_framework_binary
  ])
  if result.returncode != 0:
    print(
        'Error processing command with stdout[%s] and stderr[%s]' %
        (result.stdout, result.stderr)
    )
    return 1
  process_framework(dst, args, fat_framework, fat_framework_binary)


def process_framework(dst, args, fat_framework, fat_framework_binary):
  if args.dsym:
    dsym_out = os.path.splitext(fat_framework)[0] + '.dSYM'
    subprocess.check_call([DSYMUTIL, '-o', dsym_out, fat_framework_binary])
    subprocess.check_call([
        'zip', '-r',
        '%s/FlutterMacOS.dSYM.zip' % dst,
        '%s/FlutterMacOS.dSYM/Contents' % dst
    ])

  if args.strip:
    # copy unstripped
    unstripped_out = os.path.join(dst, 'FlutterMacOS.unstripped')
    shutil.copyfile(fat_framework_binary, unstripped_out)

    subprocess.check_call(["strip", "-x", "-S", fat_framework_binary])


if __name__ == '__main__':
  sys.exit(main())
