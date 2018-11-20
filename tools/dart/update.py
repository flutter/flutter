#!/usr/bin/python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Pulls down the current dart sdk to third_party/dart-sdk/.

You can manually force this to run again by removing
third_party/dart-sdk/STAMP_FILE, which contains the URL of the SDK that
was downloaded. Rolling works by updating LINUX_64_SDK to a new URL.
"""

import os
import shutil
import sys
import urllib
import zipfile

# How to roll the dart sdk: Just change this url! We write this to the stamp
# file after we download, and then check the stamp file for differences.
SDK_URL_BASE = ('http://gsdview.appspot.com/dart-archive/channels/dev/raw/'
                '2.1.0-dev.9.4/sdk/')

LINUX_64_SDK = 'dartsdk-linux-x64-release.zip'
MACOS_64_SDK = 'dartsdk-macos-x64-release.zip'
WINDOWS_64_SDK = 'dartsdk-windows-x64-release.zip'

# Path constants. (All of these should be absolute paths.)
THIS_DIR = os.path.abspath(os.path.dirname(__file__))
FLUTTER_DIR = os.path.abspath(os.path.join(THIS_DIR, '..', '..'))
DART_SDKS_DIR = os.path.join(FLUTTER_DIR, 'third_party/dart/tools/sdks')
PATCH_FILE = os.path.join(FLUTTER_DIR, 'tools', 'dart', 'patch_sdk.diff')

def IsStampFileUpToDate(stamp_file, sdk_url):
  if not os.path.exists(stamp_file):
    return False
  # Get the contents of the stamp file.
  with open(stamp_file, "r") as stamp_file:
    stamp_url = stamp_file.read().replace('\n', '')
    return stamp_url == sdk_url

def ExtractZipInto(zip_file, target_extract_dir, set_unix_file_modes):
  with zipfile.ZipFile(zip_file, 'r') as zip_ref:
    for zip_info in zip_ref.infolist():
      zip_ref.extract(zip_info, path=target_extract_dir)
      if set_unix_file_modes:
          # external_attr is 32 in size with the unix mode in the
          # high order 16 bit
          mode = (zip_info.external_attr >> 16) & 0xFFF
          os.chmod(os.path.join(target_extract_dir, zip_info.filename), mode)

def main():
  # Only get the SDK if we don't have a stamp for or have an out of date stamp
  # file.
  get_sdk = False
  set_unix_file_modes = True
  if sys.platform.startswith('linux'):
    zip_filename = LINUX_64_SDK
  elif sys.platform.startswith('darwin'):
    zip_filename = MACOS_64_SDK
  elif sys.platform.startswith('win'):
    zip_filename = WINDOWS_64_SDK
    set_unix_file_modes = False
  else:
    print "Platform not supported"
    return 1

  sdk_url = SDK_URL_BASE + zip_filename
  output_file = os.path.join(DART_SDKS_DIR, zip_filename)

  dart_sdk_dir = os.path.join(DART_SDKS_DIR, 'dart-sdk')

  stamp_file = os.path.join(dart_sdk_dir, 'STAMP_FILE')
  if IsStampFileUpToDate(stamp_file, sdk_url):
    return 0

  # Completely remove all traces of the previous SDK.
  if os.path.exists(dart_sdk_dir):
    shutil.rmtree(dart_sdk_dir)
  os.mkdir(dart_sdk_dir)

  urllib.urlretrieve(sdk_url, output_file)
  ExtractZipInto(output_file, DART_SDKS_DIR, set_unix_file_modes)

  # Write our stamp file so we don't redownload the sdk.
  with open(stamp_file, "w") as stamp_file:
    stamp_file.write(sdk_url)

  return 0

if __name__ == '__main__':
  sys.exit(main())
