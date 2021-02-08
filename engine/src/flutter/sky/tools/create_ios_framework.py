#!/usr/bin/env python
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import subprocess
import shutil
import sys
import os

from create_xcframework import create_xcframework

DSYMUTIL = os.path.join(os.path.dirname(__file__), '..', '..', '..',
                        'buildtools', 'mac-x64', 'clang', 'bin', 'dsymutil')

def main():
  parser = argparse.ArgumentParser(description='Creates Flutter.framework and Flutter.xcframework')

  parser.add_argument('--dst', type=str, required=True)
  parser.add_argument('--arm64-out-dir', type=str, required=True)
  parser.add_argument('--armv7-out-dir', type=str, required=True)
  # TODO(gw280): Remove --simulator-out-dir alias when all recipes are updated
  parser.add_argument('--simulator-x64-out-dir', '--simulator-out-dir', type=str, required=True)
  parser.add_argument('--simulator-arm64-out-dir', type=str, required=False)
  parser.add_argument('--strip', action="store_true", default=False)
  parser.add_argument('--dsym', action="store_true", default=False)
  parser.add_argument('--strip-bitcode', dest='strip_bitcode', action="store_true", default=False)

  args = parser.parse_args()

  fat_framework = os.path.join(args.dst, 'Flutter.framework')
  fat_simulator_framework = os.path.join(args.dst, 'sim', 'Flutter.framework')
  arm64_framework = os.path.join(args.arm64_out_dir, 'Flutter.framework')
  armv7_framework = os.path.join(args.armv7_out_dir, 'Flutter.framework')
  simulator_x64_framework = os.path.join(args.simulator_x64_out_dir, 'Flutter.framework')
  if args.simulator_arm64_out_dir is not None:
    simulator_arm64_framework = os.path.join(args.simulator_arm64_out_dir, 'Flutter.framework')
    simulator_arm64_dylib = os.path.join(simulator_arm64_framework, 'Flutter')

  arm64_dylib = os.path.join(arm64_framework, 'Flutter')
  armv7_dylib = os.path.join(armv7_framework, 'Flutter')
  simulator_x64_dylib = os.path.join(simulator_x64_framework, 'Flutter')

  if not os.path.isdir(arm64_framework):
    print('Cannot find iOS arm64 Framework at %s' % arm64_framework)
    return 1

  if not os.path.isdir(armv7_framework):
    print('Cannot find iOS armv7 Framework at %s' % armv7_framework)
    return 1

  if not os.path.isdir(simulator_x64_framework):
    print('Cannot find iOS x64 simulator Framework at %s' % simulator_framework)
    return 1

  if not os.path.isfile(arm64_dylib):
    print('Cannot find iOS arm64 dylib at %s' % arm64_dylib)
    return 1

  if not os.path.isfile(armv7_dylib):
    print('Cannot find iOS armv7 dylib at %s' % armv7_dylib)
    return 1

  if not os.path.isfile(simulator_x64_dylib):
    print('Cannot find iOS simulator dylib at %s' % simulator_dylib)
    return 1

  if not os.path.isfile(DSYMUTIL):
    print('Cannot find dsymutil at %s' % DSYMUTIL)
    return 1

  shutil.rmtree(fat_framework, True)
  shutil.copytree(arm64_framework, fat_framework)

  fat_framework_binary = os.path.join(fat_framework, 'Flutter')

  # Create the arm-only fat framework.
  subprocess.check_call([
    'lipo',
    arm64_dylib,
    armv7_dylib,
    '-create',
    '-output',
    fat_framework_binary
  ])
  process_framework(args, fat_framework, fat_framework_binary)

  if args.simulator_arm64_out_dir is not None:
    shutil.rmtree(fat_simulator_framework, True)
    shutil.copytree(simulator_arm64_framework, fat_simulator_framework)

    fat_simulator_framework_binary = os.path.join(fat_simulator_framework, 'Flutter')

    # Create the arm64/x64 simulator fat framework.
    subprocess.check_call([
      'lipo',
      simulator_x64_dylib,
      simulator_arm64_dylib,
      '-create',
      '-output',
      fat_simulator_framework_binary
    ])
    process_framework(args, fat_simulator_framework, fat_simulator_framework_binary)
    simulator_framework = fat_simulator_framework
  else:
    simulator_framework = simulator_x64_framework

  # Create XCFramework from the arm-only fat framework and the arm64/x64 simulator frameworks, or just the
  # x64 simulator framework if only that one exists.
  xcframeworks = [simulator_framework, fat_framework]
  create_xcframework(location=args.dst, name='Flutter', frameworks=xcframeworks)

  # Add the x64 simulator into the fat framework
  subprocess.check_call([
    'lipo',
    arm64_dylib,
    armv7_dylib,
    simulator_x64_dylib,
    '-create',
    '-output',
    fat_framework_binary
  ])

  process_framework(args, fat_framework, fat_framework_binary)


def process_framework(args, fat_framework, fat_framework_binary):
  if args.strip_bitcode:
    subprocess.check_call(['xcrun', 'bitcode_strip', '-r', fat_framework_binary, '-o', fat_framework_binary])

  if args.dsym:
    dsym_out = os.path.splitext(fat_framework)[0] + '.dSYM'
    subprocess.check_call([DSYMUTIL, '-o', dsym_out, fat_framework_binary])

  if args.strip:
    # copy unstripped
    unstripped_out = os.path.join(args.dst, 'Flutter.unstripped')
    shutil.copyfile(fat_framework_binary, unstripped_out)

    subprocess.check_call(["strip", "-x", "-S", fat_framework_binary])


if __name__ == '__main__':
  sys.exit(main())
