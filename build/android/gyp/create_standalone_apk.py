#!/usr/bin/env python
#
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Combines stripped libraries and incomplete APK into single standalone APK.

"""

import optparse
import os
import shutil
import sys
import tempfile

from util import build_utils
from util import md5_check

def CreateStandaloneApk(options):
  def DoZip():
    with tempfile.NamedTemporaryFile(suffix='.zip') as intermediate_file:
      intermediate_path = intermediate_file.name
      shutil.copy(options.input_apk_path, intermediate_path)
      apk_path_abs = os.path.abspath(intermediate_path)
      build_utils.CheckOutput(
          ['zip', '-r', '-1', apk_path_abs, 'lib'],
          cwd=options.libraries_top_dir)
      shutil.copy(intermediate_path, options.output_apk_path)

  input_paths = [options.input_apk_path, options.libraries_top_dir]
  record_path = '%s.standalone.stamp' % options.input_apk_path
  md5_check.CallAndRecordIfStale(
      DoZip,
      record_path=record_path,
      input_paths=input_paths)


def main():
  parser = optparse.OptionParser()
  parser.add_option('--libraries-top-dir',
      help='Top directory that contains libraries '
      '(i.e. library paths are like '
      'libraries_top_dir/lib/android_app_abi/foo.so).')
  parser.add_option('--input-apk-path', help='Path to incomplete APK.')
  parser.add_option('--output-apk-path', help='Path for standalone APK.')
  parser.add_option('--stamp', help='Path to touch on success.')
  options, _ = parser.parse_args()

  required_options = ['libraries_top_dir', 'input_apk_path', 'output_apk_path']
  build_utils.CheckOptions(options, parser, required=required_options)

  CreateStandaloneApk(options)

  if options.stamp:
    build_utils.Touch(options.stamp)


if __name__ == '__main__':
  sys.exit(main())
