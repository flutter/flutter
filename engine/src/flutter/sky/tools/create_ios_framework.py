#!/usr/bin/env python
# Copyright 2016 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import subprocess
import shutil
import sys
import os


def main():
  parser = argparse.ArgumentParser(description='Creates Flutter.framework')

  parser.add_argument('--dst', type=str, required=True)
  parser.add_argument('--device-out-dir', type=str, required=True)
  parser.add_argument('--simulator-out-dir', type=str, required=True)

  args = parser.parse_args()

  fat_framework = os.path.join(args.dst, 'Flutter.framework')
  device_framework = os.path.join(args.device_out_dir, 'Flutter.framework')
  simulator_framework = os.path.join(args.simulator_out_dir, 'Flutter.framework')

  device_dylib = os.path.join(device_framework, 'Flutter')
  simulator_dylib = os.path.join(simulator_framework, 'Flutter')

  if not os.path.isdir(device_framework):
    print 'Cannot find iOS device Framework at', device_framework
    return 1

  if not os.path.isdir(simulator_framework):
    print 'Cannot find iOS simulator Framework at', simulator_framework
    return 1

  if not os.path.isfile(device_dylib):
    print 'Cannot find iOS device dylib at', device_dylib
    return 1

  if not os.path.isfile(simulator_dylib):
    print 'Cannot find iOS simulator dylib at', simulator_dylib
    return 1

  shutil.rmtree(fat_framework, True)
  shutil.copytree(device_framework, fat_framework)

  subprocess.call([
    'lipo',
    device_dylib,
    simulator_dylib,
    '-create',
    '-output',
    os.path.join(fat_framework, 'Flutter')
  ])


if __name__ == '__main__':
  sys.exit(main())
