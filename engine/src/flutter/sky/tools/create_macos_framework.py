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

  fat_framework_bundle = os.path.join(dst, 'FlutterMacOS.framework')
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

  sky_utils.copy_tree(arm64_framework, fat_framework_bundle, symlinks=True)

  regenerate_symlinks(fat_framework_bundle)

  fat_framework_binary = os.path.join(fat_framework_bundle, 'Versions', 'A', 'FlutterMacOS')

  # Create the arm64/x64 fat framework.
  sky_utils.lipo([arm64_dylib, x64_dylib], fat_framework_binary)

  # Make the framework readable and executable: u=rwx,go=rx.
  subprocess.check_call(['chmod', '755', fat_framework_bundle])

  # Add group and other readability to all files.
  versions_path = os.path.join(fat_framework_bundle, 'Versions')
  subprocess.check_call(['chmod', '-R', 'og+r', versions_path])
  # Find all the files below the target dir with owner execute permission
  find_subprocess = subprocess.Popen(['find', versions_path, '-perm', '-100', '-print0'],
                                     stdout=subprocess.PIPE)
  # Add execute permission for other and group for all files that had it for owner.
  xargs_subprocess = subprocess.Popen(['xargs', '-0', 'chmod', 'og+x'],
                                      stdin=find_subprocess.stdout)
  find_subprocess.wait()
  xargs_subprocess.wait()

  process_framework(dst, args, fat_framework_bundle, fat_framework_binary)

  # Create XCFramework from the arm64 and x64 fat framework.
  xcframeworks = [fat_framework_bundle]
  create_xcframework(location=dst, name='FlutterMacOS', frameworks=xcframeworks)

  if args.zip:
    zip_framework(dst)

  return 0


def regenerate_symlinks(fat_framework_bundle):
  """Regenerates the symlinks structure.

  Recipes V2 upload artifacts in CAS before integration and CAS follows symlinks.
  This logic regenerates the symlinks in the expected structure.
  """
  if os.path.islink(os.path.join(fat_framework_bundle, 'FlutterMacOS')):
    return
  os.remove(os.path.join(fat_framework_bundle, 'FlutterMacOS'))
  shutil.rmtree(os.path.join(fat_framework_bundle, 'Headers'), True)
  shutil.rmtree(os.path.join(fat_framework_bundle, 'Modules'), True)
  shutil.rmtree(os.path.join(fat_framework_bundle, 'Resources'), True)
  current_version_path = os.path.join(fat_framework_bundle, 'Versions', 'Current')
  shutil.rmtree(current_version_path, True)
  os.symlink('A', current_version_path)
  os.symlink(
      os.path.join('Versions', 'Current', 'FlutterMacOS'),
      os.path.join(fat_framework_bundle, 'FlutterMacOS')
  )
  os.symlink(
      os.path.join('Versions', 'Current', 'Headers'), os.path.join(fat_framework_bundle, 'Headers')
  )
  os.symlink(
      os.path.join('Versions', 'Current', 'Modules'), os.path.join(fat_framework_bundle, 'Modules')
  )
  os.symlink(
      os.path.join('Versions', 'Current', 'Resources'),
      os.path.join(fat_framework_bundle, 'Resources')
  )


def process_framework(dst, args, fat_framework_bundle, fat_framework_binary):
  if args.dsym:
    dsym_out = os.path.splitext(fat_framework_bundle)[0] + '.dSYM'
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
