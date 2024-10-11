#!/usr/bin/env python3
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
_out_dir = os.path.join(_src_root_dir, 'out', 'ci')
_bucket_directory = os.path.join(_out_dir, 'fuchsia_bucket')


def IsLinux():
  return platform.system() == 'Linux'


def IsMac():
  return platform.system() == 'Darwin'


def GetFuchsiaSDKPath():
  # host_os references the gn host_os
  # https://gn.googlesource.com/gn/+/main/docs/reference.md#var_host_os
  host_os = ''
  if IsLinux():
    host_os = 'linux'
  elif IsMac():
    host_os = 'mac'
  else:
    host_os = 'windows'

  return os.path.join(_src_root_dir, 'fuchsia', 'sdk', host_os)


def GetHostArchFromPlatform():
  host_arch = platform.machine()
  # platform.machine() returns AMD64 on 64-bit Windows.
  if host_arch in ['x86_64', 'AMD64']:
    return 'x64'
  elif host_arch == 'aarch64':
    return 'arm64'
  raise Exception('Unsupported host architecture: %s' % host_arch)


def GetPMBinPath():
  return os.path.join(GetFuchsiaSDKPath(), 'tools', GetHostArchFromPlatform(), 'pm')


def RunExecutable(command):
  subprocess.check_call(command, cwd=_src_root_dir)


def RunGN(variant_dir, flags):
  print('Running gn for variant "%s" with flags: %s' % (variant_dir, ','.join(flags)))
  RunExecutable([
      os.path.join('flutter', 'tools', 'gn'),
  ] + flags)

  assert os.path.exists(os.path.join(_out_dir, variant_dir))


def BuildNinjaTargets(variant_dir, targets):
  assert os.path.exists(os.path.join(_out_dir, variant_dir))

  print('Running autoninja for targets: %s' % targets)
  RunExecutable(['autoninja', '-C', os.path.join(_out_dir, variant_dir)] + targets)


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
  FindFileAndCopyTo(
      'kernel_compiler.dart.snapshot', source_root, destination_base, 'kernel_compiler.snapshot'
  )
  FindFileAndCopyTo(
      'frontend_server.dart.snapshot', source_root, destination_base,
      'flutter_frontend_server.snapshot'
  )
  FindFileAndCopyTo(
      'list_libraries.dart.snapshot', source_root, destination_base, 'list_libraries.snapshot'
  )


def CopyFlutterTesterBinIfExists(source, destination):
  source_root = os.path.join(_out_dir, source)
  destination_base = os.path.join(destination, 'flutter_binaries')
  FindFileAndCopyTo('flutter_tester', source_root, destination_base)


def CopyZirconFFILibIfExists(source, destination):
  source_root = os.path.join(_out_dir, source)
  destination_base = os.path.join(destination, 'flutter_binaries')
  FindFileAndCopyTo('libzircon_ffi.so', source_root, destination_base)


def CopyToBucketWithMode(source, destination, aot, product, runner_type, api_level):
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
  CreateFarPackage(pm_bin, far_base, key_path, destination, api_level)
  patched_sdk_dirname = '%s_runner_patched_sdk' % runner_type
  patched_sdk_dir = os.path.join(source_root, patched_sdk_dirname)
  dest_sdk_path = os.path.join(destination, patched_sdk_dirname)
  if not os.path.exists(dest_sdk_path):
    CopyPath(patched_sdk_dir, dest_sdk_path)
  CopyGenSnapshotIfExists(source_root, destination)
  CopyFlutterTesterBinIfExists(source_root, destination)
  CopyZirconFFILibIfExists(source_root, destination)


def CopyToBucket(src, dst, product=False):
  api_level = ReadTargetAPILevel()
  CopyToBucketWithMode(src, dst, False, product, 'flutter', api_level)
  CopyToBucketWithMode(src, dst, True, product, 'flutter', api_level)
  CopyToBucketWithMode(src, dst, False, product, 'dart', api_level)
  CopyToBucketWithMode(src, dst, True, product, 'dart', api_level)


def ReadTargetAPILevel():
  filename = os.path.join(os.path.dirname(__file__), 'gn-sdk/src/gn_configs.gni')
  with open(filename) as f:
    for line in f:
      line = line.strip()
      if line.startswith('fuchsia_target_api_level'):
        return line.split('=')[-1].strip()
  assert False, 'No fuchsia_target_api_level found in ' + filename


def CopyVulkanDepsToBucket(src, dst, arch):
  sdk_path = GetFuchsiaSDKPath()
  deps_bucket_path = os.path.join(_bucket_directory, dst)
  if not os.path.exists(deps_bucket_path):
    FindFileAndCopyTo('VkLayer_khronos_validation.json', '%s/pkg' % (sdk_path), deps_bucket_path)
    FindFileAndCopyTo(
        'VkLayer_khronos_validation.so', '%s/arch/%s' % (sdk_path, arch), deps_bucket_path
    )


def CopyIcuDepsToBucket(src, dst):
  source_root = os.path.join(_out_dir, src)
  deps_bucket_path = os.path.join(_bucket_directory, dst)
  FindFileAndCopyTo('icudtl.dat', source_root, deps_bucket_path)


def CopyBuildToBucket(runtime_mode, arch, optimized, product):
  unopt = "_unopt" if not optimized else ""

  out_dir = 'fuchsia_%s%s_%s/' % (runtime_mode, unopt, arch)
  bucket_dir = 'flutter/%s/%s%s/' % (arch, runtime_mode, unopt)
  deps_dir = 'flutter/%s/deps/' % (arch)

  CopyToBucket(out_dir, bucket_dir, product)
  CopyVulkanDepsToBucket(out_dir, deps_dir, arch)
  CopyIcuDepsToBucket(out_dir, deps_dir)

  # Copy the CIPD YAML template from the source directory to be next to the bucket
  # we are about to package.
  cipd_yaml = os.path.join(_script_dir, 'fuchsia.cipd.yaml')
  CopyFiles(cipd_yaml, os.path.join(_bucket_directory, 'fuchsia.cipd.yaml'))

  # Copy the license files from the source directory to be next to the bucket we
  # are about to package.
  bucket_root = os.path.join(_bucket_directory, 'flutter')
  licenses_root = os.path.join(_src_root_dir, 'flutter/ci/licenses_golden')
  license_files = ['licenses_flutter', 'licenses_fuchsia', 'licenses_skia']
  for license in license_files:
    src_path = os.path.join(licenses_root, license)
    dst_path = os.path.join(bucket_root, license)
    CopyPath(src_path, dst_path)


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
  # TODO ricardoamador: remove this check when python 2 is deprecated.
  stdout = stdout if isinstance(stdout, str) else stdout.decode('UTF-8')
  match = re.search(r'No matching instances\.', stdout)
  if match:
    return False
  else:
    return True


def RunCIPDCommandWithRetries(command):
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


def ProcessCIPDPackage(upload, engine_version):
  if not upload or not IsLinux():
    RunCIPDCommandWithRetries([
        'cipd', 'pkg-build', '-pkg-def', 'fuchsia.cipd.yaml', '-out',
        os.path.join(_bucket_directory, 'fuchsia.cipd')
    ])
    return

  # Everything after this point will only run iff `upload==true` and
  # `IsLinux() == true`
  assert (upload)
  assert (IsLinux())
  if engine_version is None:
    print('--upload requires --engine-version to be specified.')
    return

  tag = 'git_revision:%s' % engine_version
  already_exists = CheckCIPDPackageExists('flutter/fuchsia', tag)
  if already_exists:
    print('CIPD package flutter/fuchsia tag %s already exists!' % tag)
    return

  RunCIPDCommandWithRetries([
      'cipd',
      'create',
      '-pkg-def',
      'fuchsia.cipd.yaml',
      '-ref',
      'latest',
      '-tag',
      tag,
  ])


def BuildTarget(
    runtime_mode, arch, optimized, enable_lto, enable_legacy, asan, dart_version_git_info,
    prebuilt_dart_sdk, build_targets
):
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
  if not enable_legacy:
    flags.append('--no-fuchsia-legacy')
  if asan:
    flags.append('--asan')
  if not dart_version_git_info:
    flags.append('--no-dart-version-git-info')
  if not prebuilt_dart_sdk:
    flags.append('--no-prebuilt-dart-sdk')

  RunGN(out_dir, flags)
  BuildNinjaTargets(out_dir, build_targets)

  return


def main():
  parser = argparse.ArgumentParser()

  parser.add_argument(
      '--cipd-dry-run',
      default=False,
      action='store_true',
      help='If set, creates the CIPD package but does not upload it.'
  )

  parser.add_argument(
      '--upload',
      default=False,
      action='store_true',
      help='If set, uploads the CIPD package and tags it as the latest.'
  )

  parser.add_argument('--engine-version', required=False, help='Specifies the flutter engine SHA.')

  parser.add_argument(
      '--unoptimized',
      action='store_true',
      default=False,
      help='If set, disables compiler optimization for the build.'
  )

  parser.add_argument(
      '--runtime-mode', type=str, choices=['debug', 'profile', 'release', 'all'], default='all'
  )

  parser.add_argument('--archs', type=str, choices=['x64', 'arm64', 'all'], default='all')

  parser.add_argument(
      '--asan',
      action='store_true',
      default=False,
      help='If set, enables address sanitization (including leak sanitization) for the build.'
  )

  parser.add_argument(
      '--no-lto', action='store_true', default=False, help='If set, disables LTO for the build.'
  )

  parser.add_argument(
      '--no-legacy',
      action='store_true',
      default=False,
      help='If set, disables legacy code for the build.'
  )

  parser.add_argument(
      '--skip-build',
      action='store_true',
      default=False,
      help='If set, skips building and just creates packages.'
  )

  parser.add_argument(
      '--targets',
      default='',
      help=('Comma-separated list; adds additional targets to build for '
            'Fuchsia.')
  )

  parser.add_argument(
      '--no-dart-version-git-info',
      action='store_true',
      default=False,
      help='If set, turns off the Dart SDK git hash check.'
  )

  parser.add_argument(
      '--no-prebuilt-dart-sdk',
      action='store_true',
      default=False,
      help='If set, builds the Dart SDK locally instead of using the prebuilt Dart SDK.'
  )

  parser.add_argument(
      '--copy-unoptimized-debug-artifacts',
      action='store_true',
      default=False,
      help='If set, unoptimized debug artifacts will be copied into CIPD along '
      'with optimized builds. This is a hack to allow infra to make '
      'and copy two debug builds, one with ASAN and one without.'
  )

  # TODO(http://fxb/110639): Deprecate this in favor of multiple runtime parameters
  parser.add_argument(
      '--skip-remove-buckets',
      action='store_true',
      default=False,
      help='This allows for multiple runtimes to exist in the default bucket directory. If '
      'set, will skip over the removal of existing artifacts in the bucket directory '
      '(which is the default behavior).'
  )

  args = parser.parse_args()
  build_mode = args.runtime_mode
  if (not args.skip_remove_buckets):
    RemoveDirectoryIfExists(_bucket_directory)

  archs = ['x64', 'arm64'] if args.archs == 'all' else [args.archs]
  runtime_modes = ['debug', 'profile', 'release']
  product_modes = [False, False, True]

  optimized = not args.unoptimized
  enable_lto = not args.no_lto
  enable_legacy = not args.no_legacy

  # Build buckets
  for arch in archs:
    for i in range(len(runtime_modes)):
      runtime_mode = runtime_modes[i]
      product = product_modes[i]
      if build_mode == 'all' or runtime_mode == build_mode:
        if not args.skip_build:
          BuildTarget(
              runtime_mode, arch, optimized, enable_lto, enable_legacy, args.asan,
              not args.no_dart_version_git_info, not args.no_prebuilt_dart_sdk,
              args.targets.split(",") if args.targets else ['flutter']
          )
        CopyBuildToBucket(runtime_mode, arch, optimized, product)

        # This is a hack. The recipe for building and uploading Fuchsia to CIPD
        # builds both a debug build (debug without ASAN) and unoptimized debug
        # build (debug with ASAN). To copy both builds into CIPD, the recipe
        # runs build_fuchsia_artifacts.py in optimized mode and tells
        # build_fuchsia_artifacts.py to also copy_unoptimized_debug_artifacts.
        #
        # TODO(akbiggs): Consolidate Fuchsia's building and copying logic to
        # avoid ugly hacks like this.
        if args.copy_unoptimized_debug_artifacts and runtime_mode == 'debug' and optimized:
          CopyBuildToBucket(runtime_mode, arch, not optimized, product)

  # Set revision to HEAD if empty and remove upload. This is to support
  # presubmit workflows.
  should_upload = args.upload
  engine_version = args.engine_version
  if not engine_version:
    engine_version = 'HEAD'
    should_upload = False

  # Create and optionally upload CIPD package
  if args.cipd_dry_run or args.upload:
    ProcessCIPDPackage(should_upload, engine_version)

  return 0


if __name__ == '__main__':
  sys.exit(main())
