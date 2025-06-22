# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import shutil
import subprocess
import sys

from dataclasses import dataclass

# Imports from //flutter/build/pyutil.
sys.path.insert(1, os.path.join(os.path.dirname(__file__), os.pardir))
from pyutil.file_util import symlink

# This script creates symlinks to Apple SDKs, Platforms, and host toolchain
# under //flutter/prebuilts.
PREBUILTS = os.path.realpath(os.path.join(
  os.path.dirname(__file__), os.pardir, os.pardir, 'flutter', 'prebuilts',
))

# Supported SDKs.
SDKS = ['iphoneos', 'iphonesimulator', 'macosx']


def parse_arguments():
  """Parses command-line arguments."""
  parser = argparse.ArgumentParser()
  parser.add_argument(
    '--as-gclient-hook',
    default=False,
    action='store_true',
    help='Whether the script is running as a gclient hook.',
  )
  parser.add_argument(
    '--print-paths',
    default=False,
    action='store_true',
    help='Print the SDK paths in key=value form.',
  )
  parser.add_argument(
    '--symlink',
    type=str,
    help='Whether to create a symlink in the buildroot to the SDK.',
  )
  parser.add_argument(
    '--sdk',
    choices=SDKS,
    help='Which SDK to find.',
  )
  return parser.parse_args()


def get_toolchain_path() -> str:
  """Returns path for the host toolchain."""
  xcode_path = subprocess.check_output(['xcode-select', '-print-path'], timeout=300).decode('utf-8').strip()
  return os.path.join(xcode_path, 'Toolchains/XcodeDefault.xctoolchain')


def get_platform_path(sdk) -> str:
  """Returns the platform path for the specified SDK."""
  return subprocess.check_output(['xcrun', '--sdk', sdk, '--show-sdk-platform-path'], timeout=300).decode('utf-8').strip()


def get_sdk_path(sdk) -> str:
  """Returns the SDK path for the specified SDK."""
  return subprocess.check_output(['xcrun', '--sdk', sdk, '--show-sdk-path'], timeout=300).decode('utf-8').strip()


@dataclass
class TargetSdk:
  """A target-platform SDK."""
  name: str
  platform_path: str
  sdk_path: str


@dataclass
class SdkInfo:
  """The host toolchain and all requested SDK paths."""
  toolchain_path: str
  sdks: list


def get_sdk_info(sdks) -> SdkInfo:
  """Collects paths for host toolchain and all specified SDKs."""
  sdk_info = SdkInfo(get_toolchain_path(), [])
  for sdk in sdks:
    platform_path = get_platform_path(sdk)
    sdk_path = get_sdk_path(sdk)
    sdk_info.sdks.append(TargetSdk(sdk, platform_path, sdk_path))
  return sdk_info


def print_paths(sdk_info) -> None:
  """Prints all SDK paths in key=value from to stdout."""
  print('toolchain_path="%s"' % sdk_info.toolchain_path)
  for sdk in sdk_info.sdks:
    print('%s_platform_path="%s"' % (sdk.name, sdk.platform_path))
    print('%s_sdk_path="%s"' % (sdk.name, sdk.sdk_path))


def create_symlink(target_dir, orig_path) -> str:
  """Creates a symlink in target_dir that points to orig_path and has the same basename."""
  target_path = os.path.join(target_dir, os.path.basename(orig_path))
  symlink(orig_path, target_path)
  return target_path


def create_symlinks(sdk_info, symlink_path, delete_existing_links) -> SdkInfo:
  """
  Creates SDK symlinks under symlink_path.
  Returns an SdkInfo with paths updated to use the symlinks instead of original paths.
  """
  platforms_path = os.path.join(symlink_path, 'Platforms')
  sdks_path = os.path.join(symlink_path, 'SDKs')

  if delete_existing_links:
    # Remove any old files created by this script under the prebuilts dir.
    if os.path.isdir(platforms_path):
      shutil.rmtree(platforms_path)
    if os.path.isdir(sdks_path):
      shutil.rmtree(sdks_path)

  # Create toolchain symlink.
  toolchain_path = create_symlink(sdks_path, sdk_info.toolchain_path)
  symlink_sdk_info = SdkInfo(toolchain_path, [])
  for sdk in sdk_info.sdks:
    platform_path = create_symlink(platforms_path, sdk.platform_path)
    sdk_path = create_symlink(sdks_path, sdk.sdk_path)
    symlink_sdk_info.sdks.append(TargetSdk(sdk.name, platform_path, sdk_path))
  return symlink_sdk_info


def main(argv):
  args = parse_arguments()

  # On CI, Xcode is not yet installed when gclient hooks are being run.
  # This is because the version of Xcode that CI installs might depend on the
  # contents of the repo, so the repo must be set up first, which includes
  # running the gclient hooks. Instead, on CI, this script will be run during
  # GN.
  running_on_luci = os.environ.get('LUCI_CONTEXT') is not None
  if running_on_luci and args.as_gclient_hook:
    return 0

  # Gather SDK paths.
  sdks = [args.sdk] if args.sdk else SDKS
  sdk_info = get_sdk_info(sdks)

  # For non-LUCI runs, default symlink_dir to the prebuilts dir.
  symlink_dir = args.symlink
  if not running_on_luci and symlink_dir is None:
    symlink_dir = PREBUILTS

  # Create symlinks.
  if symlink_dir:
    sdk_info = create_symlinks(sdk_info, symlink_dir, args.as_gclient_hook)

  # Print paths to stdout.
  if args.print_paths:
    print_paths(sdk_info)

  return 0


if __name__ == '__main__':
  if sys.platform != 'darwin':
    raise Exception('This script only runs on Mac')
  sys.exit(main(sys.argv))
