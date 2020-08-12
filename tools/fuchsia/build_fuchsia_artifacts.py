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
import re
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
_fuchsia_base = 'flutter/shell/platform/fuchsia'


def IsLinux():
  return platform.system() == 'Linux'


def IsMac():
  return platform.system() == 'Darwin'

def GetFuchsiaSDKPath():
  # host_os references the gn host_os
  # https://gn.googlesource.com/gn/+/master/docs/reference.md#var_host_os
  host_os = ''
  if IsLinux():
    host_os = 'linux'
  elif IsMac():
    host_os = 'mac'
  else:
    host_os = 'windows'

  return os.path.join(_src_root_dir, 'fuchsia', 'sdk', host_os)


def GetPMBinPath():
  return os.path.join(GetFuchsiaSDKPath(), 'tools', 'pm')


def RunExecutable(command):
  subprocess.check_call(command, cwd=_src_root_dir)


def RunGN(variant_dir, flags):
  print('Running gn for variant "%s" with flags: %s' %
        (variant_dir, ','.join(flags)))
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


def FindFileAndCopyTo(file_name, source, dest_parent, dst_name=None):
  found = FindFile(file_name, source)
  if not dst_name:
    dst_name = file_name
  if found:
    dst_path = os.path.join(dest_parent, dst_name)
    CopyPath(found, dst_path)


def CopyGenSnapshotIfExists(source, destination):
  source_root = os.path.join(_out_dir, source)
  destination_base = os.path.join(destination, 'dart_binaries')
  FindFileAndCopyTo('gen_snapshot', source_root, destination_base)
  FindFileAndCopyTo('gen_snapshot_product', source_root, destination_base)
  FindFileAndCopyTo('kernel_compiler.dart.snapshot', source_root,
                    destination_base, 'kernel_compiler.snapshot')
  FindFileAndCopyTo('frontend_server.dart.snapshot', source_root,
                    destination_base, 'flutter_frontend_server.snapshot')
  FindFileAndCopyTo('list_libraries.dart.snapshot', source_root,
                    destination_base, 'list_libraries.snapshot')


def CopyFlutterTesterBinIfExists(source, destination):
  source_root = os.path.join(_out_dir, source)
  destination_base = os.path.join(destination, 'flutter_binaries')
  FindFileAndCopyTo('flutter_tester', source_root, destination_base)


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
  patched_sdk_dirname = '%s_runner_patched_sdk' % runner_type
  patched_sdk_dir = os.path.join(source_root, patched_sdk_dirname)
  dest_sdk_path = os.path.join(destination, patched_sdk_dirname)
  if not os.path.exists(dest_sdk_path):
    CopyPath(patched_sdk_dir, dest_sdk_path)
  CopyGenSnapshotIfExists(source_root, destination)
  CopyFlutterTesterBinIfExists(source_root, destination)


def CopyToBucket(src, dst, product=False):
  CopyToBucketWithMode(src, dst, False, product, 'flutter')
  CopyToBucketWithMode(src, dst, True, product, 'flutter')
  CopyToBucketWithMode(src, dst, False, product, 'dart')
  CopyToBucketWithMode(src, dst, True, product, 'dart')


def CopyVulkanDepsToBucket(src, dst, arch):
  sdk_path = GetFuchsiaSDKPath()
  deps_bucket_path = os.path.join(_bucket_directory, dst)
  if not os.path.exists(deps_bucket_path):
    FindFileAndCopyTo('VkLayer_khronos_validation.json', '%s/pkg' % (sdk_path), deps_bucket_path)
    FindFileAndCopyTo('VkLayer_khronos_validation.so', '%s/arch/%s' % (sdk_path, arch), deps_bucket_path)

def CopyIcuDepsToBucket(src, dst):
  source_root = os.path.join(_out_dir, src)
  deps_bucket_path = os.path.join(_bucket_directory, dst)
  FindFileAndCopyTo('icudtl.dat', source_root, deps_bucket_path)

def BuildBucket(runtime_mode, arch, optimized, product):
  unopt = "_unopt" if not optimized else ""
  out_dir = 'fuchsia_%s%s_%s/' % (runtime_mode, unopt, arch)
  bucket_dir = 'flutter/%s/%s%s/' % (arch, runtime_mode, unopt)
  deps_dir = 'flutter/%s/deps/' % (arch)
  CopyToBucket(out_dir, bucket_dir, product)
  CopyVulkanDepsToBucket(out_dir, deps_dir, arch)
  CopyIcuDepsToBucket(out_dir, deps_dir)


def CheckCIPDPackageExists(package_name, tag):
  '''Check to see if the current package/tag combo has been published'''
  command = [
    'cipd',
    'search',
    package_name,
    '-tag',
    tag,
  ]
  stdout = subprocess.check_output(command)
  match = re.search(r'No matching instances\.', stdout)
  if match:
    return False
  else:
    return True


def ProcessCIPDPackage(upload, engine_version):
  # Copy the CIPD YAML template from the source directory to be next to the bucket
  # we are about to package.
  cipd_yaml = os.path.join(_script_dir, 'fuchsia.cipd.yaml')
  CopyFiles(cipd_yaml, os.path.join(_bucket_directory, 'fuchsia.cipd.yaml'))

  tag = 'git_revision:%s' % engine_version
  already_exists = CheckCIPDPackageExists('flutter/fuchsia', tag)
  if already_exists:
    print('CIPD package flutter/fuchsia tag %s already exists!' % tag)

  if upload and IsLinux() and not already_exists:
    command = [
        'cipd', 'create', '-pkg-def', 'fuchsia.cipd.yaml', '-ref', 'latest',
        '-tag',
        tag,
    ]
  else:
    command = [
        'cipd', 'pkg-build', '-pkg-def', 'fuchsia.cipd.yaml', '-out',
        os.path.join(_bucket_directory, 'fuchsia.cipd')
    ]

  # Retry up to three times.  We've seen CIPD fail on verification in some
  # instances. Normally verification takes slightly more than 1 minute when
  # it succeeds.
  num_tries = 3
  for tries in range(num_tries):
    try:
      subprocess.check_call(command, cwd=_bucket_directory)
      break
    except subprocess.CalledProcessError:
      print('Failed %s times' % tries + 1)
      if tries == num_tries - 1:
        raise

def GetRunnerTarget(runner_type, product, aot):
  base = '%s/%s:' % (_fuchsia_base, runner_type)
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

def BuildTarget(runtime_mode, arch, optimized, enable_lto, asan, additional_targets=[]):
  unopt = "_unopt" if not optimized else ""
  out_dir = 'fuchsia_%s%s_%s' % (runtime_mode, unopt, arch)
  flags = [
      '--fuchsia',
      '--fuchsia-cpu',
      arch,
      '--runtime-mode',
      runtime_mode,
  ]

  if not optimized:
    flags.append('--unoptimized')

  if not enable_lto:
    flags.append('--no-lto')
  if asan:
    flags.append('--asan')

  RunGN(out_dir, flags)
  BuildNinjaTargets(out_dir, [ 'flutter' ] + additional_targets)

  return


def main():
  parser = argparse.ArgumentParser()

  parser.add_argument(
      '--upload',
      default=False,
      action='store_true',
      help='If set, uploads the CIPD package and tags it as the latest.')

  parser.add_argument(
      '--engine-version',
      required=False,
      help='Specifies the flutter engine SHA.')

  parser.add_argument(
      '--unoptimized',
      action='store_true',
      default=False,
      help='If set, disables compiler optimization for the build.')

  parser.add_argument(
      '--runtime-mode',
      type=str,
      choices=['debug', 'profile', 'release', 'all'],
      default='all')

  parser.add_argument(
      '--archs', type=str, choices=['x64', 'arm64', 'all'], default='all')

  parser.add_argument(
      '--asan',
      action='store_true',
      default=False,
      help='If set, enables address sanitization (including leak sanitization) for the build.')

  parser.add_argument(
      '--no-lto',
      action='store_true',
      default=False,
      help='If set, disables LTO for the build.')

  parser.add_argument(
      '--skip-build',
      action='store_true',
      default=False,
      help='If set, skips building and just creates packages.')

  parser.add_argument(
      '--targets',
      default='',
      help=('Comma-separated list; adds additional targets to build for '
           'Fuchsia.'))

  args = parser.parse_args()
  RemoveDirectoryIfExists(_bucket_directory)
  build_mode = args.runtime_mode

  archs = ['x64', 'arm64'] if args.archs == 'all' else [args.archs]
  runtime_modes = ['debug', 'profile', 'release']
  product_modes = [False, False, True]

  optimized = not args.unoptimized
  enable_lto = not args.no_lto

  for arch in archs:
    for i in range(3):
      runtime_mode = runtime_modes[i]
      product = product_modes[i]
      if build_mode == 'all' or runtime_mode == build_mode:
        if not args.skip_build:
          BuildTarget(runtime_mode, arch, optimized, enable_lto, args.asan, args.targets.split(","))
        BuildBucket(runtime_mode, arch, optimized, product)

  if args.upload:
    if args.engine_version is None:
      print('--upload requires --engine-version to be specified.')
      return 1
    ProcessCIPDPackage(args.upload, args.engine_version)
  return 0


if __name__ == '__main__':
  sys.exit(main())
