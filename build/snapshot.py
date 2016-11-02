#!/usr/bin/env python
# Copyright 2016 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import subprocess
import os
import sys


def main():
  parser = argparse.ArgumentParser(description='Snapshot a Flutter application')

  parser.add_argument('--snapshotter-path', type=str, required=True,
                      help='The Flutter snapshotter')
  parser.add_argument('--app-dir', type=str, required=True,
                      help='The root of the app')
  parser.add_argument('--main-dart', type=str, required=True,
                      help='The main.dart file to use')
  parser.add_argument('--packages', type=str, required=True,
                      help='The package map to use')
  parser.add_argument('--snapshot', type=str, required=True,
                      help='Path to application snapshot')
  parser.add_argument('--depfile', type=str, required=True,
                      help='Where to output dependency information')
  parser.add_argument('--build-output', type=str, required=True,
                      help='Target name used in the depfile')

  args = parser.parse_args()

  result = subprocess.call([
    args.snapshotter_path,
    '--packages=%s' % args.packages,
    '--snapshot=%s' % args.snapshot,
    '--depfile=%s' % args.depfile,
    '--build-output=%s' % args.build_output,
    args.main_dart,
  ], cwd=args.app_dir)

  return result


if __name__ == '__main__':
  sys.exit(main())
