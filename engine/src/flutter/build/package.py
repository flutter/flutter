#!/usr/bin/env python
# Copyright 2016 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import subprocess
import os
import sys


def main():
  parser = argparse.ArgumentParser(description='Package a Flutter application')

  parser.add_argument('--root', type=str, required=True,
                      help='The root of the output directory')
  parser.add_argument('--flutter-root', type=str, required=True,
                      help='The root of the Flutter SDK')
  parser.add_argument('--dart', type=str, required=True,
                      help='The Dart binary to use')
  parser.add_argument('--flutter-tools-packages', type=str, required=True,
                      help='The package map for the Flutter tool')
  parser.add_argument('--flutter-tools-main', type=str, required=True,
                      help='The main.dart file for the Flutter tool')
  parser.add_argument('--working-dir', type=str, required=True,
                      help='The directory where to put intermediate files')
  parser.add_argument('--app-dir', type=str, required=True,
                      help='The root of the app')
  parser.add_argument('--packages', type=str, required=True,
                      help='The package map to use')
  parser.add_argument('--snapshot', type=str, required=True,
                      help='Path to application snapshot')
  parser.add_argument('--output-file', type=str, required=True,
                      help='Where to output application bundle')

  args = parser.parse_args()

  env = os.environ.copy()
  env['LD_LIBRARY_PATH'] = args.root
  env['FLUTTER_ROOT'] = args.flutter_root

  result = subprocess.call([
    args.dart,
    '--packages=%s' % args.flutter_tools_packages,
    args.flutter_tools_main,
    '--working-dir=%s' % args.working_dir,
    '--packages=%s' % args.packages,
    '--snapshot=%s' % args.snapshot,
    '--output-file=%s' % args.output_file,
    '--header=#!mojo mojo:flutter_content_handler',
  ], env=env, cwd=args.app_dir)

  return result


if __name__ == '__main__':
  sys.exit(main())
