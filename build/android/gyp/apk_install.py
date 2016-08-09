#!/usr/bin/env python
#
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Installs an APK.

"""

import optparse
import os
import re
import sys

from util import build_device
from util import build_utils
from util import md5_check

BUILD_ANDROID_DIR = os.path.join(os.path.dirname(__file__), '..')
sys.path.append(BUILD_ANDROID_DIR)

from pylib import constants
from pylib.utils import apk_helper


def GetNewMetadata(device, apk_package):
  """Gets the metadata on the device for the apk_package apk."""
  output = device.RunShellCommand('ls -l /data/app/')
  # Matches lines like:
  # -rw-r--r-- system   system    7376582 2013-04-19 16:34 \
  # org.chromium.chrome.shell.apk
  # -rw-r--r-- system   system    7376582 2013-04-19 16:34 \
  # org.chromium.chrome.shell-1.apk
  apk_matcher = lambda s: re.match('.*%s(-[0-9]*)?(.apk)?$' % apk_package, s)
  matches = filter(apk_matcher, output)
  return matches[0] if matches else None

def HasInstallMetadataChanged(device, apk_package, metadata_path):
  """Checks if the metadata on the device for apk_package has changed."""
  if not os.path.exists(metadata_path):
    return True

  with open(metadata_path, 'r') as expected_file:
    return expected_file.read() != device.GetInstallMetadata(apk_package)


def RecordInstallMetadata(device, apk_package, metadata_path):
  """Records the metadata from the device for apk_package."""
  metadata = GetNewMetadata(device, apk_package)
  if not metadata:
    raise Exception('APK install failed unexpectedly.')

  with open(metadata_path, 'w') as outfile:
    outfile.write(metadata)


def main():
  parser = optparse.OptionParser()
  parser.add_option('--apk-path',
      help='Path to .apk to install.')
  parser.add_option('--split-apk-path',
      help='Path to .apk splits (can specify multiple times, causes '
      '--install-multiple to be used.',
      action='append')
  parser.add_option('--android-sdk-tools',
      help='Path to the Android SDK build tools folder. ' +
           'Required when using --split-apk-path.')
  parser.add_option('--install-record',
      help='Path to install record (touched only when APK is installed).')
  parser.add_option('--build-device-configuration',
      help='Path to build device configuration.')
  parser.add_option('--stamp',
      help='Path to touch on success.')
  parser.add_option('--configuration-name',
      help='The build CONFIGURATION_NAME')
  options, _ = parser.parse_args()

  device = build_device.GetBuildDeviceFromPath(
      options.build_device_configuration)
  if not device:
    return

  constants.SetBuildType(options.configuration_name)

  serial_number = device.GetSerialNumber()
  apk_package = apk_helper.GetPackageName(options.apk_path)

  metadata_path = '%s.%s.device.time.stamp' % (options.apk_path, serial_number)

  # If the APK on the device does not match the one that was last installed by
  # the build, then the APK has to be installed (regardless of the md5 record).
  force_install = HasInstallMetadataChanged(device, apk_package, metadata_path)


  def Install():
    if options.split_apk_path:
      device.InstallSplitApk(options.apk_path, options.split_apk_path)
    else:
      device.Install(options.apk_path, reinstall=True)

    RecordInstallMetadata(device, apk_package, metadata_path)
    build_utils.Touch(options.install_record)


  record_path = '%s.%s.md5.stamp' % (options.apk_path, serial_number)
  md5_check.CallAndRecordIfStale(
      Install,
      record_path=record_path,
      input_paths=[options.apk_path],
      force=force_install)

  if options.stamp:
    build_utils.Touch(options.stamp)


if __name__ == '__main__':
  sys.exit(main())
