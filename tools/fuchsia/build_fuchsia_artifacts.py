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


def FindFile(name, path):
  for root, dirs, files in os.walk(path):
    if name in files:
      return os.path.join(root, name)


def CopyGenSnapshotIfExists(source, destination):
  source_root = os.path.join(_out_dir, source)
  destination_base = os.path.join(destination, 'dart_binaries')
  gen_snapshot = FindFile('gen_snapshot', source_root)
  gen_snapshot_product = FindFile('gen_snapshot_product', source_root)
  if gen_snapshot:
    dst_path = os.path.join(destination_base, 'gen_snapshot')
    CopyPath(gen_snapshot, dst_path)
  if gen_snapshot_product:
    dst_path = os.path.join(destination_base, 'gen_snapshot_product')
    CopyPath(gen_snapshot_product, dst_path)


def CopyToBucketWithMode(source, destination, aot, product, runner_type):
  mode = 'aot' if aot else 'jit'
  product_suff = '_product' if product else ''
  runner_name = '%s_%s%s_runner' % (runner_type, mode, product_suff)
  far_dir_name = '%s_far' % runner_name
  source_root = os.path.join(_out_dir, source)
  far_base = os.path.join(source_root, far_dir_name)
  CreateMetaPackage(far_base, runner_name)
  pm_bin = GetPMBinPath()
  key_path = os.path.join(_script_dir, 'development.key')

  destination = os.path.join(_bucket_directory, destination, mode)
  CreateFarPackage(pm_bin, far_base, key_path, destination)
  patched_sdk_dir = os.path.join(source_root, 'flutter_runner_patched_sdk')
  dest_sdk_path = os.path.join(destination, 'flutter_runner_patched_sdk')
  if not os.path.exists(dest_sdk_path):
    CopyPath(patched_sdk_dir, dest_sdk_path)
  CopyGenSnapshotIfExists(source_root, destination)


def CopyToBucket(src, dst, product=False):
  CopyToBucketWithMode(src, dst, False, product, 'flutter')
  CopyToBucketWithMode(src, dst, True, product, 'flutter')
  CopyToBucketWithMode(src, dst, False, product, 'dart')


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


def GetRunnerTarget(runner_type, product, aot):
  base = 'flutter/shell/platform/fuchsia/%s:' % runner_type
  if 'dart' in runner_type:
    target = 'dart_'
  else:
    target = 'flutter_'
  if aot:
    target += 'aot_'
  else:
    target += 'jit_'
  if product:
    target += 'product_'
  target += 'runner'
  return base + target


def GetTargetsToBuild(product=False):
  targets_to_build = [
      # The Flutter Runner.
      GetRunnerTarget('flutter', product, False),
      GetRunnerTarget('flutter', product, True),
      # The Dart Runner.
      GetRunnerTarget('dart_runner', product, False),
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
