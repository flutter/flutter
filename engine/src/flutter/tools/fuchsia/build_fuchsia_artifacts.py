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
import platform
import shutil
import subprocess
import sys
import tempfile

from gather_flutter_runner_artifacts import CreateMetaPackage, CopyPath
from gen_package import CreateFarPackage

_script_dir = os.path.abspath(os.path.join(os.path.realpath(__file__), '..'))
_src_root_dir = os.path.join(_script_dir, '..', '..', '..')
_out_dir = os.path.join(_src_root_dir, 'out')
_bucket_directory = os.path.join(_out_dir, 'fuchsia_bucket')


def IsLinux():
  return platform.system() == 'Linux'


def IsMac():
  return platform.system() == 'Darwin'


def GetPMBinPath():
  # host_os references the gn host_os
  # https://gn.googlesource.com/gn/+/master/docs/reference.md#var_host_os
  host_os = ''
  if IsLinux():
    host_os = 'linux'
  elif IsMac():
    host_os = 'mac'
  else:
    host_os = 'windows'

  return os.path.join(_src_root_dir, 'fuchsia', 'sdk', host_os, 'tools', 'pm')


def RunExecutable(command):
  subprocess.check_call(command, cwd=_src_root_dir)


def RunGN(variant_dir, flags):
  RunExecutable([
      os.path.join('flutter', 'tools', 'gn'),
  ] + flags)

  assert os.path.exists(os.path.join(_out_dir, variant_dir))


def BuildNinjaTargets(variant_dir, targets):
  assert os.path.exists(os.path.join(_out_dir, variant_dir))

  RunExecutable(['autoninja', '-C',
                 os.path.join(_out_dir, variant_dir)] + targets)


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


def CopyToBucket(source, destination, product=False):
  runner_name = 'flutter_jit_runner'
  if product:
    runner_name = 'flutter_jit_product_runner'
  far_dir = '%s_far' % runner_name
  source_root = os.path.join(_out_dir, source)
  source = os.path.join(source_root, far_dir)
  CreateMetaPackage(source, runner_name)
  pm_bin = GetPMBinPath()
  key_path = os.path.join(_script_dir, 'development.key')

  destination = os.path.join(_bucket_directory, destination)
  CreateFarPackage(pm_bin, source, key_path, destination)
  patched_sdk_dir = os.path.join(source_root, 'flutter_runner_patched_sdk')
  dest_sdk_path = os.path.join(destination, 'flutter_runner_patched_sdk')
  CopyPath(patched_sdk_dir, dest_sdk_path)


def BuildBucket():
  RemoveDirectoryIfExists(_bucket_directory)

  CopyToBucket('fuchsia_debug/', 'flutter/debug/')
  CopyToBucket('fuchsia_profile/', 'flutter/profile/')
  CopyToBucket('fuchsia_release/', 'flutter/release/', True)


def ProcessCIPDPakcage(upload, engine_version):
  # Copy the CIPD YAML template from the source directory to be next to the bucket
  # we are about to package.
  cipd_yaml = os.path.join(_script_dir, 'fuchsia.cipd.yaml')
  CopyFiles(cipd_yaml, os.path.join(_bucket_directory, 'fuchsia.cipd.yaml'))

  if upload and IsLinux():
    command = [
        'cipd', 'create', '-pkg-def', 'fuchsia.cipd.yaml', '-ref', 'latest',
        '-tag',
        'git_revision:%s' % engine_version
    ]
  else:
    command = [
        'cipd', 'pkg-build', '-pkg-def', 'fuchsia.cipd.yaml', '-out',
        os.path.join(_bucket_directory, 'fuchsia.cipd')
    ]

  subprocess.check_call(command, cwd=_bucket_directory)


def GetTargetsToBuild(product=False):
  product_suffix = '_product'
  if not product:
    product_suffix = ''
  targets_to_build = [
      # The Flutter Runner.
      'flutter/shell/platform/fuchsia/flutter:flutter_jit%s_runner' %
      product_suffix,

      # The Dart Runner.
      # 'flutter/shell/platform/fuchsia/dart:dart',
  ]
  return targets_to_build


def main():
  parser = argparse.ArgumentParser()

  parser.add_argument(
      '--upload',
      default=False,
      action='store_true',
      help='If set, uploads the CIPD package and tags it as the latest.')

  parser.add_argument(
      '--engine-version',
      required=True,
      help='Specifies the flutter engine SHA.')

  args = parser.parse_args()

  common_flags = [
      '--fuchsia',
      # The source does not require LTO and LTO is not wired up for targets.
      '--no-lto',
  ]

  RunGN('fuchsia_debug', common_flags + ['--runtime-mode', 'debug'])

  RunGN('fuchsia_profile', common_flags + ['--runtime-mode', 'profile'])

  RunGN('fuchsia_release', common_flags + ['--runtime-mode', 'release'])

  BuildNinjaTargets('fuchsia_debug', GetTargetsToBuild())
  BuildNinjaTargets('fuchsia_profile', GetTargetsToBuild())
  BuildNinjaTargets('fuchsia_release', GetTargetsToBuild(True))

  BuildBucket()

  ProcessCIPDPakcage(args.upload, args.engine_version)


if __name__ == '__main__':
  main()
