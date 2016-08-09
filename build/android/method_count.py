#! /usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import re
import sys

from pylib import constants
from pylib.sdk import dexdump

sys.path.append(os.path.join(constants.DIR_SOURCE_ROOT, 'build', 'util', 'lib',
                             'common'))
import perf_tests_results_helper


_METHOD_IDS_SIZE_RE = re.compile(r'^method_ids_size +: +(\d+)$')

def MethodCount(dexfile):
  for line in dexdump.DexDump(dexfile, file_summary=True):
    m = _METHOD_IDS_SIZE_RE.match(line)
    if m:
      return m.group(1)
  raise Exception('"method_ids_size" not found in dex dump of %s' % dexfile)

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument(
      '--apk-name', help='Name of the APK to which the dexfile corresponds.')
  parser.add_argument('dexfile')

  args = parser.parse_args()

  if not args.apk_name:
    dirname, basename = os.path.split(args.dexfile)
    while basename:
      if 'apk' in basename:
        args.apk_name = basename
        break
      dirname, basename = os.path.split(dirname)
    else:
      parser.error(
          'Unable to determine apk name from %s, '
          'and --apk-name was not provided.' % args.dexfile)

  method_count = MethodCount(args.dexfile)
  perf_tests_results_helper.PrintPerfResult(
      '%s_methods' % args.apk_name, 'total', [method_count], 'methods')
  return 0

if __name__ == '__main__':
  sys.exit(main())

