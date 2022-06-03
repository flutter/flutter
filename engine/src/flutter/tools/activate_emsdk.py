#!/usr/bin/env python

# Copyright 2022 Google LLC
#
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import subprocess
import sys

EMSDK_ROOT = os.path.join('src', 'buildtools', 'emsdk')

EMSDK_PATH = os.path.join(EMSDK_ROOT, 'emsdk.py')

# See lib/web_ui/README.md for instructions on updating the EMSDK version.
EMSDK_VERSION = '3.1.3'


def main():
  try:
    subprocess.check_call([
        sys.executable, EMSDK_PATH, 'install', EMSDK_VERSION
    ])
  except subprocess.CalledProcessError:
    print('Failed to install emsdk')
    return 1
  try:
    subprocess.check_call([
        sys.executable, EMSDK_PATH, 'activate', EMSDK_VERSION
    ])
  except subprocess.CalledProcessError:
    print('Failed to activate emsdk')
    return 1


if __name__ == '__main__':
  sys.exit(main())
