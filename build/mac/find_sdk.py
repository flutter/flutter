#!/usr/bin/env python3
#
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Prints the lowest locally available SDK version greater than or equal to a
given minimum sdk version to standard output.

Usage:
  python find_sdk.py 10.6  # Ignores SDKs < 10.6
"""

import json
import os
import re
import subprocess
import sys

from optparse import OptionParser

sys.path.insert(1, '../../build')
from pyutil.file_util import symlink


def parse_version(version_str):
  """'10.6' => [10, 6]"""
  return [int(x) for x in re.findall(r'(\d+)', version_str)]


def main():
  parser = OptionParser()
  parser.add_option("--verify",
                    action="store_true", dest="verify", default=False,
                    help="return the sdk argument and warn if it doesn't exist")
  parser.add_option("--sdk_path",
                    action="store", type="string", dest="sdk_path", default="",
                    help="user-specified SDK path; bypasses verification")
  parser.add_option("--print_sdk_path",
                    action="store_true", dest="print_sdk_path", default=False,
                    help="Additionaly print the path the SDK (appears first).")
  parser.add_option("--symlink",
                    action="store", type="string", dest="symlink", default="",
                    help="Whether to create a symlink in the buildroot to the SDK.")
  (options, args) = parser.parse_args()
  min_sdk_version = args[0]

  job = subprocess.Popen(['xcode-select', '-print-path'],
                         universal_newlines=True,
                         stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT)
  out, err = job.communicate()
  if job.returncode != 0:
    sys.stderr.writelines([out, err])
    raise Exception(('Error %d running xcode-select, you might have to run '
      '|sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer| '
      'if you are using Xcode 4.') % job.returncode)

  sdk_command = ['xcodebuild',
    '-showsdks',
    '-json']
  sdk_json_output = subprocess.check_output(sdk_command)
  sdk_json = json.loads(sdk_json_output)

  best_sdk = None
  sdk_output = None

  # Xcode can return the same version for different symlinked paths.
  # Sort by path to keep the list stable between runs.
  for properties in sorted(list(sdk_json), key=lambda d: d['sdkPath']):
    # Filter out macOS DriverKit, watchOS, AppleTV, and other SDKs.
    if properties.get('platform') != 'macosx' or 'driver' in properties.get('canonicalName'):
      continue
    sdk_version = properties['sdkVersion']
    parsed_version = parse_version(sdk_version)
    if (parsed_version >= parse_version(min_sdk_version) and
          (not best_sdk or parsed_version < parse_version(best_sdk))):
      best_sdk = sdk_version
      sdk_output = properties['sdkPath']

  if not best_sdk:
    print(sdk_json_output)
    raise Exception('No %s+ SDK found' % min_sdk_version)

  if options.verify and best_sdk != min_sdk_version and not options.sdk_path:
    print(sdk_json_output)
    sys.stderr.writelines([
      '',
      '                                           vvvvvvv',
      '',
      'This build requires the %s SDK, but it was not found on your system.' \
        % min_sdk_version,
      'Either install it, or explicitly set mac_sdk in your gn args.',
      '',
      '                                           ^^^^^^^',
      ''])
    return min_sdk_version

  if options.symlink or options.print_sdk_path:
    if options.symlink:
      symlink_target = os.path.join(options.symlink, 'SDKs', os.path.basename(sdk_output))
      symlink(sdk_output, symlink_target)
      sdk_output = symlink_target

    if options.print_sdk_path:
      print(sdk_output)

  return best_sdk


if __name__ == '__main__':
  if sys.platform != 'darwin':
    raise Exception("This script only runs on Mac")
  print((main()))
