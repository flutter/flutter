#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Generates and zip the ios flutter framework including the architecture
# dependent snapshot.

import argparse
import os
import platform
import shutil
import subprocess
import sys

from create_xcframework import create_xcframework  # pylint: disable=import-error

ARCH_SUBPATH = 'mac-arm64' if platform.processor() == 'arm' else 'mac-x64'
DSYMUTIL = os.path.join(
    os.path.dirname(__file__), '..', '..', 'buildtools', ARCH_SUBPATH, 'clang', 'bin', 'dsymutil'
)

buildroot_dir = os.path.abspath(os.path.join(os.path.realpath(__file__), '..', '..', '..', '..'))


def main():
  parser = argparse.ArgumentParser(
      description=(
          'Creates Flutter.framework, Flutter.xcframework and '
          'copies architecture-dependent gen_snapshot binaries to output dir'
      )
  )

  parser.add_argument('--dst', type=str, required=True)
  parser.add_argument('--x64-out-dir', type=str)
  parser.add_argument('--arm64-out-dir', type=str, required=True)
  parser.add_argument('--simulator-x64-out-dir', type=str, required=True)
  parser.add_argument('--simulator-arm64-out-dir', type=str, required=False)
  parser.add_argument('--strip', action='store_true', default=False)
  parser.add_argument('--dsym', action='store_true', default=False)

  args = parser.parse_args()

  dst = (args.dst if os.path.isabs(args.dst) else os.path.join(buildroot_dir, args.dst))

  arm64_out_dir = (
      args.arm64_out_dir
      if os.path.isabs(args.arm64_out_dir) else os.path.join(buildroot_dir, args.arm64_out_dir)
  )

  x64_out_dir = None
  if args.x64_out_dir:
    x64_out_dir = (
        args.x64_out_dir
        if os.path.isabs(args.x64_out_dir) else os.path.join(buildroot_dir, args.x64_out_dir)
    )

  simulator_x64_out_dir = None
  if args.simulator_x64_out_dir:
    simulator_x64_out_dir = (
        args.simulator_x64_out_dir if os.path.isabs(args.simulator_x64_out_dir) else
        os.path.join(buildroot_dir, args.simulator_x64_out_dir)
    )

  framework = os.path.join(dst, 'Flutter.framework')
  simulator_framework = os.path.join(dst, 'sim', 'Flutter.framework')
  arm64_framework = os.path.join(arm64_out_dir, 'Flutter.framework')
  simulator_x64_framework = os.path.join(simulator_x64_out_dir, 'Flutter.framework')

  simulator_arm64_out_dir = None
  if args.simulator_arm64_out_dir:
    simulator_arm64_out_dir = (
        args.simulator_arm64_out_dir if os.path.isabs(args.simulator_arm64_out_dir) else
        os.path.join(buildroot_dir, args.simulator_arm64_out_dir)
    )

  if args.simulator_arm64_out_dir is not None:
    simulator_arm64_framework = os.path.join(simulator_arm64_out_dir, 'Flutter.framework')

  if not os.path.isdir(arm64_framework):
    print('Cannot find iOS arm64 Framework at %s' % arm64_framework)
    return 1

  if not os.path.isdir(simulator_x64_framework):
    print('Cannot find iOS x64 simulator Framework at %s' % simulator_framework)
    return 1

  if not os.path.isfile(DSYMUTIL):
    print('Cannot find dsymutil at %s' % DSYMUTIL)
    return 1

  create_framework(
      args, dst, framework, arm64_framework, simulator_framework, simulator_x64_framework,
      simulator_arm64_framework
  )

  extension_safe_dst = os.path.join(dst, 'extension_safe')
  create_extension_safe_framework(
      args, extension_safe_dst, '%s_extension_safe' % arm64_out_dir,
      '%s_extension_safe' % simulator_x64_out_dir, '%s_extension_safe' % simulator_arm64_out_dir
  )

  generate_gen_snapshot(dst, x64_out_dir, arm64_out_dir)
  zip_archive(dst)
  return 0

def create_extension_safe_framework( # pylint: disable=too-many-arguments
    args, dst, arm64_out_dir, simulator_x64_out_dir, simulator_arm64_out_dir
):
  framework = os.path.join(dst, 'Flutter.framework')
  simulator_framework = os.path.join(dst, 'sim', 'Flutter.framework')
  arm64_framework = os.path.join(arm64_out_dir, 'Flutter.framework')
  simulator_x64_framework = os.path.join(simulator_x64_out_dir, 'Flutter.framework')
  simulator_arm64_framework = os.path.join(simulator_arm64_out_dir, 'Flutter.framework')

  if not os.path.isdir(arm64_framework):
    print('Cannot find extension safe iOS arm64 Framework at %s' % arm64_framework)
    return 1

  if not os.path.isdir(simulator_x64_framework):
    print('Cannot find extension safe iOS x64 simulator Framework at %s' % simulator_x64_framework)
    return 1

  create_framework(
      args, dst, framework, arm64_framework, simulator_framework, simulator_x64_framework,
      simulator_arm64_framework
  )
  return 0

def create_framework(  # pylint: disable=too-many-arguments
    args, dst, framework, arm64_framework, simulator_framework,
    simulator_x64_framework, simulator_arm64_framework
):
  arm64_dylib = os.path.join(arm64_framework, 'Flutter')
  simulator_x64_dylib = os.path.join(simulator_x64_framework, 'Flutter')
  simulator_arm64_dylib = os.path.join(simulator_arm64_framework, 'Flutter')
  if not os.path.isfile(arm64_dylib):
    print('Cannot find iOS arm64 dylib at %s' % arm64_dylib)
    return 1

  if not os.path.isfile(simulator_x64_dylib):
    print('Cannot find iOS simulator dylib at %s' % simulator_x64_dylib)
    return 1

  # Compute dsym output paths, if enabled.
  framework_dsym = None
  simulator_dsym = None
  if args.dsym:
    framework_dsym = framework + '.dSYM'
    simulator_dsym = simulator_framework + '.dSYM'

  # Emit the framework for physical devices.
  shutil.rmtree(framework, True)
  shutil.copytree(arm64_framework, framework)
  framework_binary = os.path.join(framework, 'Flutter')
  process_framework(args, dst, framework_binary, framework_dsym)

  # Emit the framework for simulators.
  if args.simulator_arm64_out_dir is not None:
    shutil.rmtree(simulator_framework, True)
    shutil.copytree(simulator_arm64_framework, simulator_framework)

    simulator_framework_binary = os.path.join(simulator_framework, 'Flutter')

    # Create the arm64/x64 simulator fat framework.
    subprocess.check_call([
        'lipo', simulator_x64_dylib, simulator_arm64_dylib, '-create', '-output',
        simulator_framework_binary
    ])
    process_framework(args, dst, simulator_framework_binary, simulator_dsym)
  else:
    simulator_framework = simulator_x64_framework

  # Create XCFramework from the arm-only fat framework and the arm64/x64
  # simulator frameworks, or just the x64 simulator framework if only that one
  # exists.
  xcframeworks = [simulator_framework, framework]
  dsyms = [simulator_dsym, framework_dsym] if args.dsym else None
  create_xcframework(location=dst, name='Flutter', frameworks=xcframeworks, dsyms=dsyms)

  # Add the x64 simulator into the fat framework.
  subprocess.check_call([
      'lipo', arm64_dylib, simulator_x64_dylib, '-create', '-output', framework_binary
  ])

  process_framework(args, dst, framework_binary, framework_dsym)
  return 0


def embed_codesign_configuration(config_path, contents):
  with open(config_path, 'w') as file:
    file.write('\n'.join(contents) + '\n')


def zip_archive(dst):
  ios_file_with_entitlements = ['gen_snapshot_arm64']
  ios_file_without_entitlements = [
      'Flutter.xcframework/ios-arm64/Flutter.framework/Flutter',
      'Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework/Flutter',
      'extension_safe/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter',
      'extension_safe/Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework/Flutter'
  ]
  embed_codesign_configuration(os.path.join(dst, 'entitlements.txt'), ios_file_with_entitlements)

  embed_codesign_configuration(
      os.path.join(dst, 'without_entitlements.txt'), ios_file_without_entitlements
  )

  subprocess.check_call([
      'zip',
      '-r',
      'artifacts.zip',
      'gen_snapshot_arm64',
      'Flutter.xcframework',
      'entitlements.txt',
      'without_entitlements.txt',
      'extension_safe/Flutter.xcframework',
  ],
                        cwd=dst)


def process_framework(args, dst, framework_binary, dsym):
  if dsym:
    subprocess.check_call([DSYMUTIL, '-o', dsym, framework_binary])

  if args.strip:
    # copy unstripped
    unstripped_out = os.path.join(dst, 'Flutter.unstripped')
    shutil.copyfile(framework_binary, unstripped_out)
    subprocess.check_call(['strip', '-x', '-S', framework_binary])


def generate_gen_snapshot(dst, x64_out_dir, arm64_out_dir):
  if x64_out_dir:
    x64_path = os.path.join(x64_out_dir, 'gen_snapshot_x64')
    _generate_gen_snapshot(x64_path, os.path.join(dst, 'gen_snapshot_x64'))

  if arm64_out_dir:
    arm64_path = os.path.join(arm64_out_dir, 'gen_snapshot_arm64')
    _generate_gen_snapshot(arm64_path, os.path.join(dst, 'gen_snapshot_arm64'))


def _generate_gen_snapshot(gen_snapshot_path, destination):
  if not os.path.isfile(gen_snapshot_path):
    print('Cannot find gen_snapshot at %s' % gen_snapshot_path)
    sys.exit(1)

  shutil.copy2(gen_snapshot_path, destination)


if __name__ == '__main__':
  sys.exit(main())
