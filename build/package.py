#!/usr/bin/env python
# Copyright 2016 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import subprocess
import os
import StringIO
import sys
import zipfile


def main():
  parser = argparse.ArgumentParser(description='Package a Flutter application')

  parser.add_argument('--snapshotter', type=str, required=True,
                      help='The snapshot binary to use')
  parser.add_argument('--main-dart', type=str, required=True,
                      help='The main.dart file to use')
  parser.add_argument('--packages', type=str, required=True,
                      help='The package map to use')
  parser.add_argument('--snapshot', type=str, required=True,
                      help='Path to application snapshot')
  parser.add_argument('--depfile', type=str, required=True,
                      help='Where to output dependency information')
  parser.add_argument('--build-output', type=str, required=True,
                      help='The final target to use in the dependency information')
  parser.add_argument('--bundle', type=str, required=True,
                      help='Where to output application bundle')
  parser.add_argument('--bundle-header', type=str, required=True,
                      help='String to prepend to bundle')

  args = parser.parse_args()

  result = subprocess.call([
    args.snapshotter,
    '--packages=%s' % args.packages,
    '--snapshot=%s' % args.snapshot,
    '--depfile=%s' % args.depfile,
    '--build-output=%s' % args.build_output,
    args.main_dart,
  ])

  if result != 0:
    return result

  archive = StringIO.StringIO()
  with zipfile.ZipFile(archive, 'w') as z:
    z.write(args.snapshot, 'snapshot_blob.bin', zipfile.ZIP_DEFLATED)

  with open(args.bundle, 'w') as f:
    if args.bundle_header:
        f.write(args.bundle_header)
        f.write('\n')
    f.write(archive.getvalue())


if __name__ == '__main__':
  sys.exit(main())
