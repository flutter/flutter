#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import shutil
import sys
import os

from create_xcframework import create_xcframework  # pylint: disable=import-error
import sky_utils  # pylint: disable=import-error


def main():
  parser = argparse.ArgumentParser(
      description='Creates FlutterMacOS.framework and FlutterMacOS.xcframework for macOS'
  )

  parser.add_argument('--dst', type=str, required=True)
  parser.add_argument('--arm64-out-dir', type=str, required=True)
  parser.add_argument('--x64-out-dir', type=str, required=True)
  parser.add_argument('--strip', action='store_true', default=False)
  parser.add_argument('--dsym', action='store_true', default=False)
  parser.add_argument('--zip', action='store_true', default=False)

  args = parser.parse_args()

  dst = args.dst if os.path.isabs(args.dst) else sky_utils.buildroot_relative_path(args.dst)
  arm64_out_dir = (
      args.arm64_out_dir if os.path.isabs(args.arm64_out_dir) else
      sky_utils.buildroot_relative_path(args.arm64_out_dir)
  )
  x64_out_dir = (
      args.x64_out_dir
      if os.path.isabs(args.x64_out_dir) else sky_utils.buildroot_relative_path(args.x64_out_dir)
  )

  arm64_framework = os.path.join(arm64_out_dir, 'FlutterMacOS.framework')
  if not os.path.isdir(arm64_framework):
    print('Cannot find macOS arm64 Framework at %s' % arm64_framework)
    return 1

  x64_framework = os.path.join(x64_out_dir, 'FlutterMacOS.framework')
  if not os.path.isdir(x64_framework):
    print('Cannot find macOS x64 Framework at %s' % x64_framework)
    return 1

  arm64_dylib = os.path.join(arm64_framework, 'FlutterMacOS')
  if not os.path.isfile(arm64_dylib):
    print('Cannot find macOS arm64 dylib at %s' % arm64_dylib)
    return 1

  x64_dylib = os.path.join(x64_framework, 'FlutterMacOS')
  if not os.path.isfile(x64_dylib):
    print('Cannot find macOS x64 dylib at %s' % x64_dylib)
    return 1

  fat_framework = os.path.join(dst, 'FlutterMacOS.framework')
  sky_utils.create_fat_macos_framework(fat_framework, arm64_framework, x64_framework)
  process_framework(dst, args, fat_framework)

  # Create XCFramework from the arm64 and x64 fat framework.
  xcframeworks = [fat_framework]
  create_xcframework(location=dst, name='FlutterMacOS', frameworks=xcframeworks)

  if args.zip:
    zip_framework(dst)

  return 0


def process_framework(dst, args, fat_framework):
  fat_framework_binary = os.path.join(fat_framework, 'Versions', 'A', 'FlutterMacOS')
  if args.dsym:
    dsym_out = os.path.splitext(fat_framework)[0] + '.dSYM'
    sky_utils.extract_dsym(fat_framework_binary, dsym_out)
    if args.zip:
      dsym_dst = os.path.join(dst, 'FlutterMacOS.dSYM')
      sky_utils.create_zip(dsym_dst, 'FlutterMacOS.dSYM.zip', ['.'])
      # Double zip to make it consistent with legacy artifacts.
      # TODO(fujino): remove this once https://github.com/flutter/flutter/issues/125067 is resolved
      sky_utils.create_zip(dsym_dst, 'FlutterMacOS.dSYM_.zip', ['FlutterMacOS.dSYM.zip'])

      # Overwrite the FlutterMacOS.dSYM.zip with the double-zipped archive.
      dsym_final_src_path = os.path.join(dsym_dst, 'FlutterMacOS.dSYM_.zip')
      dsym_final_dst_path = os.path.join(dst, 'FlutterMacOS.dSYM.zip')
      shutil.move(dsym_final_src_path, dsym_final_dst_path)

  if args.strip:
    unstripped_out = os.path.join(dst, 'FlutterMacOS.unstripped')
    sky_utils.strip_binary(fat_framework_binary, unstripped_out)


def zip_framework(dst):
  framework_dst = os.path.join(dst, 'FlutterMacOS.framework')
  sky_utils.write_codesign_config(os.path.join(framework_dst, 'entitlements.txt'), [])
  sky_utils.write_codesign_config(
      os.path.join(framework_dst, 'without_entitlements.txt'),
      [
          # TODO(cbracken): Remove the zip file from the path when outer zip is removed.
          'FlutterMacOS.framework.zip/Versions/A/FlutterMacOS'
      ]
  )
  sky_utils.create_zip(framework_dst, 'FlutterMacOS.framework.zip', ['.'])

  # Double zip to make it consistent with legacy artifacts.
  # TODO(fujino): remove this once https://github.com/flutter/flutter/issues/125067 is resolved
  sky_utils.create_zip(
      framework_dst,
      'FlutterMacOS.framework_.zip',
      [
          'FlutterMacOS.framework.zip',
          # TODO(cbracken): Move these files to inner zip before removing the outer zip.
          'entitlements.txt',
          'without_entitlements.txt',
      ]
  )

  # Overwrite the FlutterMacOS.framework.zip with the double-zipped archive.
  final_src_path = os.path.join(framework_dst, 'FlutterMacOS.framework_.zip')
  final_dst_path = os.path.join(dst, 'FlutterMacOS.framework.zip')
  shutil.move(final_src_path, final_dst_path)

  zip_xcframework_archive(dst)


def zip_xcframework_archive(dst):
  sky_utils.write_codesign_config(os.path.join(dst, 'entitlements.txt'), [])

  sky_utils.write_codesign_config(
      os.path.join(dst, 'without_entitlements.txt'), [
          'FlutterMacOS.xcframework/macos-arm64_x86_64/'
          'FlutterMacOS.framework/Versions/A/FlutterMacOS'
      ]
  )

  sky_utils.create_zip(
      dst,
      'framework.zip',
      [
          'FlutterMacOS.xcframework',
          'entitlements.txt',
          'without_entitlements.txt',
      ],
  )


if __name__ == '__main__':
  sys.exit(main())
