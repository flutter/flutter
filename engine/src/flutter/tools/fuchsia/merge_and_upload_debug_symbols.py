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
import tempfile
import yaml


def IsLinux():
  return platform.system() == 'Linux'


def CreateCIPDDefinition(target_arch, out_dir):
  pkg_def = {}
  pkg_def['package'] = 'flutter/fuchsia-debug-symbols-%s' % target_arch
  desc = 'Flutter and Dart runner debug symbols for Fuchsia. Target architecture: %s.' % target_arch
  pkg_def['description'] = desc
  pkg_def['install_mode'] = 'copy'
  pkg_def['data'] = [{'dir': os.path.basename(os.path.normpath(out_dir))}]
  return pkg_def


def WriteCIPDDefinition(target_arch, out_dir):
  _, temp_file = tempfile.mkstemp(suffix='.yaml')
  with open(temp_file, 'w') as f:
    yaml.dump(
        CreateCIPDDefinition(target_arch, out_dir), f, default_flow_style=False)
  return temp_file


def ProcessCIPDPackage(upload, cipd_yaml, engine_version, out_dir, target_arch):
  _packaging_dir = os.path.abspath(os.path.join(out_dir, os.pardir))
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

  subprocess.check_call(command, cwd=_packaging_dir)


def NormalizeDirPathForRsync(path):
  norm_path = os.path.normpath(path)
  return norm_path + os.path.sep


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

  out_dir = NormalizeDirPathForRsync(args.out_dir)
  if os.path.exists(out_dir):
    print 'Directory: %s is not empty, deleting it.' % out_dir
    shutil.rmtree(out_dir)
  os.makedirs(out_dir)

  for symbol_dir in symbol_dirs:
    subprocess.check_output(
        ['rsync', '--recursive',
         NormalizeDirPathForRsync(symbol_dir), out_dir])

  cipd_def = WriteCIPDDefinition(args.target_arch, out_dir)
  ProcessCIPDPackage(args.upload, cipd_def, args.engine_version, out_dir,
                     args.target_arch)
  return 0


if __name__ == '__main__':
  sys.exit(main())
