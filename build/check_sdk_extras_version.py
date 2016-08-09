#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

'''Checks the status of an Android SDK package.

Verifies the given package has been installed from the Android SDK Manager and
that its version is at least the minimum version required by the project
configuration.
'''

import argparse
import json
import os
import re
import sys


COLORAMA_ROOT = os.path.join(os.path.dirname(__file__),
                 os.pardir, 'third_party', 'colorama', 'src')

sys.path.append(COLORAMA_ROOT)
import colorama


UDPATE_SCRIPT_PATH = 'build/install-android-sdks.sh'

SDK_EXTRAS_JSON_FILE = os.path.join(os.path.dirname(__file__),
                                    'android_sdk_extras.json')

PACKAGE_VERSION_PATTERN = r'^Pkg\.Revision=(?P<version>\d+).*$'

PKG_NOT_FOUND_MSG = ('Error while checking Android SDK extras versions. '
                     'Could not find the "{package_id}" package in '
                     '{checked_location}. Please run {script} to download it.')
UPDATE_NEEDED_MSG = ('Error while checking Android SDK extras versions. '
                     'Version {minimum_version} or greater is required for the '
                     'package "{package_id}". Version {actual_version} found. '
                     'Please run {script} to update it.')
REQUIRED_VERSION_ERROR_MSG = ('Error while checking Android SDK extras '
                              'versions. '
                              'Could not retrieve the required version for '
                              'package "{package_id}".')


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('--package-id',
                      help=('id of the package to check for. The list of '
                            'available packages and their ids can be obtained '
                            'by running '
                            'third_party/android_tools/sdk/tools/android list '
                            'sdk --extended'))
  parser.add_argument('--package-location',
                      help='path to the package\'s expected install location.',
                      metavar='DIR')
  parser.add_argument('--stamp',
                      help=('if specified, a stamp file will be created at the '
                            'provided location.'),
                      metavar='FILE')

  args = parser.parse_args()

  if not ShouldSkipVersionCheck():
    minimum_version = GetRequiredMinimumVersion(args.package_id)
    CheckPackageVersion(args.package_id, args.package_location, minimum_version)

  # Create the stamp file.
  if args.stamp:
    with open(args.stamp, 'a'):
      os.utime(args.stamp, None)

  sys.exit(0)

def ExitError(msg):
  sys.exit(colorama.Fore.MAGENTA + colorama.Style.BRIGHT + msg +
           colorama.Style.RESET_ALL)


def GetRequiredMinimumVersion(package_id):
  with open(SDK_EXTRAS_JSON_FILE, 'r') as json_file:
    packages = json.load(json_file)

  for package in packages:
    if package['package_id'] == package_id:
      return int(package['version'].split('.')[0])

  ExitError(REQUIRED_VERSION_ERROR_MSG.format(package_id=package_id))


def CheckPackageVersion(pkg_id, location, minimum_version):
  version_file_path = os.path.join(location, 'source.properties')
  # Extracts the version of the package described by the property file. We only
  # care about the major version number here.
  version_pattern = re.compile(PACKAGE_VERSION_PATTERN, re.MULTILINE)

  if not os.path.isfile(version_file_path):
    ExitError(PKG_NOT_FOUND_MSG.format(
      package_id=pkg_id,
      checked_location=location,
      script=UDPATE_SCRIPT_PATH))

  with open(version_file_path, 'r') as f:
    match = version_pattern.search(f.read())

    if not match:
      ExitError(PKG_NOT_FOUND_MSG.format(
        package_id=pkg_id,
        checked_location=location,
        script=UDPATE_SCRIPT_PATH))

    pkg_version = int(match.group('version'))
    if pkg_version < minimum_version:
      ExitError(UPDATE_NEEDED_MSG.format(
        package_id=pkg_id,
        minimum_version=minimum_version,
        actual_version=pkg_version,
        script=UDPATE_SCRIPT_PATH))

  # Everything looks ok, print nothing.

def ShouldSkipVersionCheck():
  '''
  Bots should not run the version check, since they download the sdk extras
  in a different way.
  '''
  return bool(os.environ.get('CHROME_HEADLESS'))

if __name__ == '__main__':
  main()
