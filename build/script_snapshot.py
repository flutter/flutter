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
  parser.add_argument('--vm-snapshot-data', type=str, required=True,
                      help='Path to vm_isolate_snapshot.bin')
  parser.add_argument('--isolate-snapshot-data', type=str, required=True,
                      help='Path to isolate_snapshot.bin')
  parser.add_argument('--main-dart', type=str, required=True,
                      help='The main.dart file to use')
  parser.add_argument('--packages', type=str, required=True,
                      help='The package map to use')
  parser.add_argument('--snapshot', type=str, required=True,
                      help='Where to output application snapshot')
  parser.add_argument('--depfile', type=str, required=True,
                      help='Where to output dependency information')
  parser.add_argument('--root-build-dir', type=str, required=True,
                      help='The root build dir for --depfile and --snapshot')

  args = parser.parse_args()

  cmd = [
    args.snapshotter_path,
    '--snapshot_kind=script',
    '--vm_snapshot_data=%s' % args.vm_snapshot_data,
    '--isolate_snapshot_data=%s' % args.isolate_snapshot_data,
    '--packages=%s' % args.packages,
    '--script_snapshot=%s' % args.snapshot,
    '--dependencies=%s' % args.depfile,
    args.main_dart,
  ]

  result = subprocess.call(cmd, cwd=args.root_build_dir)
  if result != 0:
    print("Command failed: '%s'" % (" ".join(cmd)))

  return result


if __name__ == '__main__':
  sys.exit(main())
