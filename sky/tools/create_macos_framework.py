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
  parser.add_argument('--strip', action='store_true', default=False)
  parser.add_argument('--dsym', action='store_true', default=False)
  # TODO(godofredoc): Remove after recipes v2 have landed.
  parser.add_argument('--zip', action='store_true', default=False)

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
  regenerate_symlinks(fat_framework)

  fat_framework_binary = os.path.join(
      fat_framework, 'Versions', 'A', 'FlutterMacOS'
  )

  # Create the arm64/x64 fat framework.
  subprocess.check_call([
      'lipo', arm64_dylib, x64_dylib, '-create', '-output', fat_framework_binary
  ])
  process_framework(dst, args, fat_framework, fat_framework_binary)

  return 0


def regenerate_symlinks(fat_framework):
  """Regenerates the symlinks structure.

  Recipes V2 upload artifacts in CAS before integration and CAS follows symlinks.
  This logic regenerates the symlinks in the expected structure.
  """
  if os.path.islink(os.path.join(fat_framework, 'FlutterMacOS')):
    return
  os.remove(os.path.join(fat_framework, 'FlutterMacOS'))
  shutil.rmtree(os.path.join(fat_framework, 'Headers'), True)
  shutil.rmtree(os.path.join(fat_framework, 'Modules'), True)
  shutil.rmtree(os.path.join(fat_framework, 'Resources'), True)
  current_version_path = os.path.join(fat_framework, 'Versions', 'Current')
  shutil.rmtree(current_version_path, True)
  os.symlink('A', current_version_path)
  os.symlink(
      os.path.join('Versions', 'Current', 'FlutterMacOS'),
      os.path.join(fat_framework, 'FlutterMacOS')
  )
  os.symlink(
      os.path.join('Versions', 'Current', 'Headers'),
      os.path.join(fat_framework, 'Headers')
  )
  os.symlink(
      os.path.join('Versions', 'Current', 'Modules'),
      os.path.join(fat_framework, 'Modules')
  )
  os.symlink(
      os.path.join('Versions', 'Current', 'Resources'),
      os.path.join(fat_framework, 'Resources')
  )


def embed_codesign_configuration(config_path, content):
  with open(config_path, 'w') as file:
    file.write(content)


def process_framework(dst, args, fat_framework, fat_framework_binary):
  if args.dsym:
    dsym_out = os.path.splitext(fat_framework)[0] + '.dSYM'
    subprocess.check_call([DSYMUTIL, '-o', dsym_out, fat_framework_binary])
    if args.zip:
      dsym_dst = os.path.join(dst, 'FlutterMacOS.dSYM')
      subprocess.check_call(['zip', '-r', '-y', 'FlutterMacOS.dSYM.zip', '.'],
                            cwd=dsym_dst)
      # Double zip to make it consistent with legacy artifacts.
      # TODO(fujino): remove this once https://github.com/flutter/flutter/issues/125067 is resolved
      subprocess.check_call([
          'zip',
          '-y',
          'FlutterMacOS.dSYM_.zip',
          'FlutterMacOS.dSYM.zip',
      ],
                            cwd=dsym_dst)
      # Use doubled zipped file.
      dsym_final_src_path = os.path.join(dsym_dst, 'FlutterMacOS.dSYM_.zip')
      dsym_final_dst_path = os.path.join(dst, 'FlutterMacOS.dSYM.zip')
      shutil.move(dsym_final_src_path, dsym_final_dst_path)

  if args.strip:
    # copy unstripped
    unstripped_out = os.path.join(dst, 'FlutterMacOS.unstripped')
    shutil.copyfile(fat_framework_binary, unstripped_out)

    subprocess.check_call(['strip', '-x', '-S', fat_framework_binary])

  # Zip FlutterMacOS.framework.
  if args.zip:
    filepath_with_entitlements = ''

    framework_dst = os.path.join(dst, 'FlutterMacOS.framework')
    # TODO(xilaizhang): Remove the zip file from the path when outer zip is removed.
    filepath_without_entitlements = 'FlutterMacOS.framework.zip/Versions/A/FlutterMacOS'

    embed_codesign_configuration(
        os.path.join(framework_dst, 'entitlements.txt'),
        filepath_with_entitlements
    )

    embed_codesign_configuration(
        os.path.join(framework_dst, 'without_entitlements.txt'),
        filepath_without_entitlements
    )
    subprocess.check_call([
        'zip',
        '-r',
        '-y',
        'FlutterMacOS.framework.zip',
        '.',
    ],
                          cwd=framework_dst)
    # Double zip to make it consistent with legacy artifacts.
    # TODO(fujino): remove this once https://github.com/flutter/flutter/issues/125067 is resolved
    subprocess.check_call(
        [
            'zip',
            '-y',
            'FlutterMacOS.framework_.zip',
            'FlutterMacOS.framework.zip',
            # TODO(xilaizhang): Move these files to inner zip before removing the outer zip.
            'entitlements.txt',
            'without_entitlements.txt',
        ],
        cwd=framework_dst
    )
    # Use doubled zipped file.
    final_src_path = os.path.join(framework_dst, 'FlutterMacOS.framework_.zip')
    final_dst_path = os.path.join(dst, 'FlutterMacOS.framework.zip')
    shutil.move(final_src_path, final_dst_path)


if __name__ == '__main__':
  sys.exit(main())
