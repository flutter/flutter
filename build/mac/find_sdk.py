#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Prints the lowest locally available SDK version greater than or equal to a
given minimum sdk version to standard output.

Usage:
  python find_sdk.py 10.6  # Ignores SDKs < 10.6
"""

import os
import re
import subprocess
import sys


from optparse import OptionParser


def parse_version(version_str):
  """'10.6' => [10, 6]"""
  return map(int, re.findall(r'(\d+)', version_str))


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
  (options, args) = parser.parse_args()
  min_sdk_version = args[0]

  job = subprocess.Popen(['xcode-select', '-print-path'],
                         stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT)
  out, err = job.communicate()
  if job.returncode != 0:
    print >> sys.stderr, out
    print >> sys.stderr, err
    raise Exception(('Error %d running xcode-select, you might have to run '
      '|sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer| '
      'if you are using Xcode 4.') % job.returncode)
  # The Developer folder moved in Xcode 4.3.
  xcode43_sdk_path = os.path.join(
      out.rstrip(), 'Platforms/MacOSX.platform/Developer/SDKs')
  if os.path.isdir(xcode43_sdk_path):
    sdk_dir = xcode43_sdk_path
  else:
    sdk_dir = os.path.join(out.rstrip(), 'SDKs')
  sdks = [re.findall('^MacOSX(10\.\d+)\.sdk$', s) for s in os.listdir(sdk_dir)]
  sdks = [s[0] for s in sdks if s]  # [['10.5'], ['10.6']] => ['10.5', '10.6']
  sdks = [s for s in sdks  # ['10.5', '10.6'] => ['10.6']
          if parse_version(s) >= parse_version(min_sdk_version)]
  if not sdks:
    raise Exception('No %s+ SDK found' % min_sdk_version)
  best_sdk = sorted(sdks, key=parse_version)[0]

  if options.verify and best_sdk != min_sdk_version and not options.sdk_path:
    print >> sys.stderr, ''
    print >> sys.stderr, '                                           vvvvvvv'
    print >> sys.stderr, ''
    print >> sys.stderr, \
        'This build requires the %s SDK, but it was not found on your system.' \
        % min_sdk_version
    print >> sys.stderr, \
        'Either install it, or explicitly set mac_sdk in your GYP_DEFINES.'
    print >> sys.stderr, ''
    print >> sys.stderr, '                                           ^^^^^^^'
    print >> sys.stderr, ''
    return min_sdk_version

  if options.print_sdk_path:
    print subprocess.check_output(['xcodebuild', '-version', '-sdk',
                                   'macosx' + best_sdk, 'Path']).strip()

  return best_sdk


if __name__ == '__main__':
  if sys.platform != 'darwin':
    raise Exception("This script only runs on Mac")
  print main()
