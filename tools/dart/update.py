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
SDK_URL_BASE = ('http://gsdview.appspot.com/dart-archive/channels/stable/raw/'
                '1.21.0/sdk/')

LINUX_64_SDK = 'dartsdk-linux-x64-release.zip'
MACOS_64_SDK = 'dartsdk-macos-x64-release.zip'
WINDOWS_64_SDK = 'dartsdk-windows-x64-release.zip'

# Path constants. (All of these should be absolute paths.)
THIS_DIR = os.path.abspath(os.path.dirname(__file__))
MOJO_DIR = os.path.abspath(os.path.join(THIS_DIR, '..', '..'))
DART_SDK_DIR = os.path.join(MOJO_DIR, 'third_party', 'dart-sdk')
STAMP_FILE = os.path.join(DART_SDK_DIR, 'STAMP_FILE')
LIBRARIES_FILE = os.path.join(DART_SDK_DIR,'dart-sdk',
                              'lib', '_internal', 'libraries.dart')
PATCH_FILE = os.path.join(MOJO_DIR, 'tools', 'dart', 'patch_sdk.diff')

def main():
  # Only get the SDK if we don't have a stamp for or have an out of date stamp
  # file.
  get_sdk = False
  if sys.platform.startswith('linux'):
    sdk_url = SDK_URL_BASE + LINUX_64_SDK
    output_file = os.path.join(DART_SDK_DIR, LINUX_64_SDK)
  elif sys.platform.startswith('darwin'):
    sdk_url = SDK_URL_BASE + MACOS_64_SDK
    output_file = os.path.join(DART_SDK_DIR, MACOS_64_SDK)
  elif sys.platform.startswith('win'):
    sdk_url = SDK_URL_BASE + WINDOWS_64_SDK
    output_file = os.path.join(DART_SDK_DIR, WINDOWS_64_SDK)
  else:
    print "Platform not supported"
    return 1

  if not os.path.exists(STAMP_FILE):
    get_sdk = True
  else:
    # Get the contents of the stamp file.
    with open(STAMP_FILE, "r") as stamp_file:
      stamp_url = stamp_file.read().replace('\n', '')
      if stamp_url != sdk_url:
        get_sdk = True

  if get_sdk:
    # Completely remove all traces of the previous SDK.
    if os.path.exists(DART_SDK_DIR):
      shutil.rmtree(DART_SDK_DIR)
    os.mkdir(DART_SDK_DIR)

    urllib.urlretrieve(sdk_url, output_file)
    print(output_file)
    with zipfile.ZipFile(output_file, 'r') as zip_ref:
      for zip_info in zip_ref.infolist():
        zip_ref.extract(zip_info, path=DART_SDK_DIR)
        mode = (zip_info.external_attr >> 16) & 0xFFF
        os.chmod(os.path.join(DART_SDK_DIR, zip_info.filename), mode)

    # Write our stamp file so we don't redownload the sdk.
    with open(STAMP_FILE, "w") as stamp_file:
      stamp_file.write(sdk_url)

  return 0

if __name__ == '__main__':
  sys.exit(main())
