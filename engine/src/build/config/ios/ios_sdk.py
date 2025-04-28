# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import shutil
import subprocess
import sys

sys.path.insert(1, os.path.join(os.path.dirname(__file__), os.pardir, os.pardir))
from pyutil.file_util import symlink

# This script creates symlinks under flutter/prebuilts to the iphone and
# iphone simulator SDKs.

SDKs = ['iphoneos', 'iphonesimulator']

PREBUILTS = os.path.realpath(os.path.join(
  os.path.dirname(__file__), os.pardir, os.pardir, os.pardir, 'flutter', 'prebuilts',
))


def main(argv):
  parser = argparse.ArgumentParser()
  parser.add_argument(
      '--as-gclient-hook',
      default=False,
      action='store_true',
      help='Whether the script is running as a gclient hook.',
  )
  parser.add_argument(
    '--symlink',
    type=str,
    help='Whether to create a symlink in the buildroot to the SDK.',
  )
  parser.add_argument(
    '--sdk',
    choices=['iphoneos', 'iphonesimulator'],
    help='Which SDK to find.',
  )
  args = parser.parse_args()

  # On CI, Xcode is not yet installed when gclient hooks are being run.
  # This is because the version of Xcode that CI installs might depend on the
  # contents of the repo, so the repo must be set up first, which includes
  # running the gclient hooks. Instead, on CI, this script will be run during
  # GN.
  running_on_luci = os.environ.get('LUCI_CONTEXT') is not None
  if running_on_luci and args.as_gclient_hook:
    return 0

  symlink_path = args.symlink
  if not running_on_luci and symlink_path is None:
    symlink_path = PREBUILTS

  sdks = [args.sdk] if args.sdk is not None else SDKs

  sdks_path = None
  libraries_path = None
  if symlink_path:
    sdks_path = os.path.join(symlink_path, 'SDKs')
    libraries_path = os.path.join(symlink_path, 'Library')
    # Remove any old files created by this script under PREBUILTS/SDKs.
    if args.as_gclient_hook:
      if os.path.isdir(sdks_path):
        shutil.rmtree(sdks_path)
      if os.path.isdir(libraries_path):
        shutil.rmtree(libraries_path)

  for sdk in sdks:
    command =  [
      'xcrun',
      '--sdk',
      sdk,
      '--show-sdk-path',
    ]
    sdk_output = subprocess.check_output(command, timeout=300).decode('utf-8').strip()
    if symlink_path:
      symlink_target = os.path.join(sdks_path, os.path.basename(sdk_output))
      symlink(sdk_output, symlink_target)
      frameworks_location = os.path.join(sdk_output, '..', '..', 'Library', 'Frameworks')
      frameworks_symlink = os.path.join(libraries_path, 'Frameworks')
      symlink(frameworks_location, frameworks_symlink)
      sdk_output = symlink_target
    if not args.as_gclient_hook:
      print(sdk_output)
  return 0


if __name__ == '__main__':
  if sys.platform != 'darwin':
    raise Exception('This script only runs on Mac')
  sys.exit(main(sys.argv))
