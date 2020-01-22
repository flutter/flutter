#!/usr/bin/env python
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
""" Merges the debug symbols and uploads them to cipd.
"""

import argparse
import collections
import json
import os
import platform
import shutil
import subprocess
import sys
import tarfile


def IsLinux():
  return platform.system() == 'Linux'


def GetPackagingDir(out_dir):
  return os.path.abspath(os.path.join(out_dir, os.pardir))


def CreateCIPDDefinition(target_arch, out_dir):
  dir_name = os.path.basename(os.path.normpath(out_dir))
  return """
package: flutter/fuchsia-debug-symbols-%s
description: Flutter and Dart runner debug symbols for Fuchsia. Target architecture %s.
install_mode: copy
data:
  - dir: %s
""" % (target_arch, target_arch, dir_name)


# CIPD CLI needs the definition and data directory to be relative to each other.
def WriteCIPDDefinition(target_arch, out_dir):
  _packaging_dir = GetPackagingDir(out_dir)
  yaml_file = os.path.join(_packaging_dir, 'debug_symbols.cipd.yaml')
  with open(yaml_file, 'w') as f:
    cipd_def = CreateCIPDDefinition(target_arch, out_dir)
    f.write(cipd_def)
  return yaml_file


def ProcessCIPDPackage(upload, cipd_yaml, engine_version, out_dir, target_arch):
  _packaging_dir = GetPackagingDir(out_dir)
  if upload and IsLinux():
    command = [
        'cipd', 'create', '-pkg-def', cipd_yaml, '-ref', 'latest', '-tag',
        'git_revision:%s' % engine_version
    ]
  else:
    command = [
        'cipd', 'pkg-build', '-pkg-def', cipd_yaml, '-out',
        os.path.join(_packaging_dir,
                     'fuchsia-debug-symbols-%s.cipd' % target_arch)
    ]

  # Retry up to three times.  We've seen CIPD fail on verification in some
  # instances. Normally verification takes slightly more than 1 minute when
  # it succeeds.
  num_tries = 3
  for tries in range(num_tries):
    try:
      subprocess.check_call(command, cwd=_packaging_dir)
      break
    except subprocess.CalledProcessError:
      print('Failed %s times' % tries + 1)
      if tries == num_tries - 1:
        raise

def CreateTarFile(folder_path, base_dir):
  archive_name = os.path.basename(folder_path)
  tar_file_path = os.path.join(base_dir, archive_name + '.tar.bz2')
  with tarfile.open(tar_file_path, "w:bz2") as archive:
    for root, dirs, _ in os.walk(folder_path):
      for dir_name in dirs:
        dir_path = os.path.join(root, dir_name)
        archive.add(dir_path, arcname=dir_name)
  return tar_file_path


def main():
  parser = argparse.ArgumentParser()

  parser.add_argument(
      '--symbol-dirs',
      required=True,
      nargs='+',
      help='Space separated list of directories that contain the debug symbols.'
  )
  parser.add_argument(
      '--out-dir',
      required=True,
      action='store',
      dest='out_dir',
      help='Output directory where the executables will be placed.')
  parser.add_argument(
      '--target-arch', type=str, choices=['x64', 'arm64'], required=True)
  parser.add_argument(
      '--engine-version',
      required=True,
      help='Specifies the flutter engine SHA.')

  parser.add_argument('--upload', default=False, action='store_true')

  args = parser.parse_args()

  symbol_dirs = args.symbol_dirs
  for symbol_dir in symbol_dirs:
    assert os.path.exists(symbol_dir) and os.path.isdir(symbol_dir)

  arch = args.target_arch
  out_dir = os.path.join(args.out_dir,
                         'flutter-fuchsia-debug-symbols-%s' % arch)
  if os.path.exists(out_dir):
    print 'Directory: %s is not empty, deleting it.' % out_dir
    shutil.rmtree(out_dir)
  os.makedirs(out_dir)

  for symbol_dir in symbol_dirs:
    archive_path = CreateTarFile(symbol_dir, out_dir)
    print('Created archive: ' + archive_path)

  cipd_def = WriteCIPDDefinition(arch, out_dir)
  ProcessCIPDPackage(args.upload, cipd_def, args.engine_version, out_dir, arch)
  return 0


if __name__ == '__main__':
  sys.exit(main())
