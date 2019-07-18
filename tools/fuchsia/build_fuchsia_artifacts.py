#!/usr/bin/env python
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

""" Builds all Fuchsia artifacts vended by Flutter.
"""

import argparse
import errno
import os
import shutil
import subprocess
import sys

_script_dir = os.path.abspath(os.path.join(os.path.realpath(__file__), '..'))
_src_root_dir = os.path.join(_script_dir, '..', '..', '..')
_out_dir = os.path.join(_src_root_dir, 'out')
_bucket_directory = os.path.join(_out_dir, 'fuchsia_bucket')

def RunExecutable(command):
  subprocess.check_call(command, cwd=_src_root_dir)

def RunGN(variant_dir, flags):
  RunExecutable([
      os.path.join('flutter', 'tools', 'gn'),
  ] + flags)

  assert os.path.exists(os.path.join(_out_dir, variant_dir))

def BuildNinjaTargets(variant_dir, targets):
  assert os.path.exists(os.path.join(_out_dir, variant_dir))

  RunExecutable([
    'autoninja',
    '-C',
    os.path.join(_out_dir, variant_dir)
  ] + targets)


def RemoveDirectoryIfExists(path):
  if not os.path.exists(path):
    return

  if os.path.isfile(path) or os.path.islink(path):
    os.unlink(path)
  else:
    shutil.rmtree(path)

def CopyFiles(source, destination):
  try:
    shutil.copytree(source, destination)
  except OSError as error:
    if error.errno == errno.ENOTDIR:
      shutil.copy(source, destination)
    else:
      raise

def CopyToBucket(source, destination):
  source = os.path.join(_out_dir, source)
  destination = os.path.join(_bucket_directory, destination)

  assert os.path.exists(source), '"%s" does not exist!' % source

  CopyFiles(source, destination)

def BuildBucket():
  RemoveDirectoryIfExists(_bucket_directory)

  CopyToBucket('fuchsia_debug/flutter_patched_sdk', 'flutter/debug/flutter_patched_sdk')
  CopyToBucket('fuchsia_profile/flutter_patched_sdk', 'flutter/profile/flutter_patched_sdk')
  CopyToBucket('fuchsia_release/flutter_patched_sdk', 'flutter/release/flutter_patched_sdk')

  CopyToBucket('fuchsia_debug/flutter_runner', 'flutter/debug/flutter_runner')
  CopyToBucket('fuchsia_profile/flutter_runner', 'flutter/profile/flutter_runner')
  CopyToBucket('fuchsia_release/flutter_runner', 'flutter/release/flutter_runner')

  CopyToBucket('fuchsia_debug/dart_runner', 'flutter/debug/dart_runner')
  CopyToBucket('fuchsia_profile/dart_runner', 'flutter/profile/dart_runner')
  CopyToBucket('fuchsia_release/dart_runner', 'flutter/release/dart_runner')


  CopyToBucket('fuchsia_debug/icudtl.dat', 'flutter/debug/icudtl.dat')
  CopyToBucket('fuchsia_profile/icudtl.dat', 'flutter/profile/icudtl.dat')
  CopyToBucket('fuchsia_release/icudtl.dat', 'flutter/release/icudtl.dat')

def ProcessCIPDPakcage(upload, engine_version):
  # Copy the CIPD YAML template from the source directory to be next to the bucket
  # we are about to package.
  cipd_yaml = os.path.join(_script_dir, 'fuchsia.cipd.yaml')
  CopyFiles(cipd_yaml, os.path.join(_bucket_directory, 'fuchsia.cipd.yaml'))

  if upload:
    command = [
      'cipd',
      'create',
      '-pkg-def',
      'fuchsia.cipd.yaml',
      '-ref',
      'latest',
      '-tag',
      'git_revision:%s' % engine_version
    ]
  else:
    command = [
      'cipd',
      'pkg-build',
      '-pkg-def',
      'fuchsia.cipd.yaml',
      '-out',
      os.path.join(_bucket_directory, 'fuchsia.cipd')
    ]

  subprocess.check_call(command, cwd=_bucket_directory)

def main():
  parser = argparse.ArgumentParser();

  parser.add_argument('--upload', default=False, action='store_true',
      help='If set, uploads the CIPD package and tags it as the latest.')

  parser.add_argument('--engine-version', required=True,
      help='Specifies the flutter engine SHA.')

  args = parser.parse_args()

  common_flags = [
    '--fuchsia',
    # The source does not require LTO and LTO is not wired up for targets.
    '--no-lto',
  ]

  RunGN('fuchsia_debug', common_flags + [
    '--runtime-mode',
    'debug'
  ]);

  RunGN('fuchsia_profile', common_flags + [
    '--runtime-mode',
    'profile'
  ]);

  RunGN('fuchsia_release', common_flags + [
    '--runtime-mode',
    'release'
  ]);

  targets_to_build = [
    # The Flutter Runner.
    'flutter/shell/platform/fuchsia/flutter:flutter',

    # The Dart Runner.
    'flutter/shell/platform/fuchsia/dart:dart',

    # The Snapshots.
    'flutter/lib/snapshot:snapshot',
  ]

  BuildNinjaTargets('fuchsia_debug', targets_to_build)
  BuildNinjaTargets('fuchsia_profile', targets_to_build)
  BuildNinjaTargets('fuchsia_release', targets_to_build)

  BuildBucket()

  ProcessCIPDPakcage(args.upload, args.engine_version)


if __name__ == '__main__':
  main()

