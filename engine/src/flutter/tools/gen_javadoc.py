#!/usr/bin/env python
# Copyright 2017 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import subprocess
import sys

ANDROID_SRC_ROOT = 'flutter/shell/platform/android'


def main():
  if not os.path.exists(ANDROID_SRC_ROOT):
    print 'This script must be run at the root of the Flutter source tree'
    return 1

  parser = argparse.ArgumentParser(description='Runs javadoc on Flutter Android libraries')
  parser.add_argument('--out-dir', type=str, required=True)
  args = parser.parse_args()

  if not os.path.exists(args.out_dir):
    os.makedirs(args.out_dir)

  classpath = [
    ANDROID_SRC_ROOT,
    'third_party/android_tools/sdk/platforms/android-22/android.jar',
    'base/android/java/src',
    'third_party/jsr-305/src/ri/src/main/java',
  ]
  packages = [
    'io.flutter.app',
    'io.flutter.view',
    'io.flutter.plugin.editing',
    'io.flutter.plugin.common',
    'io.flutter.plugin.platform',
  ]

  return subprocess.call([
    'javadoc',
    '-classpath', ':'.join(classpath),
    '-d', args.out_dir,
  ] + packages)


if __name__ == '__main__':
  sys.exit(main())
