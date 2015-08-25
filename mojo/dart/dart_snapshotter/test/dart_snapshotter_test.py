#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import hashlib
import os
import subprocess
import sys
import tempfile

SNAPSHOT_TEST_DIR = os.path.dirname(os.path.abspath(__file__))
SRC_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(
    SNAPSHOT_TEST_DIR))))
DART_DIR = os.path.join(SRC_ROOT, 'dart')

VM_SNAPSHOT_FILES=[
  # Header files.
  'datastream.h',
  'object.h',
  'raw_object.h',
  'snapshot.h',
  'snapshot_ids.h',
  'symbols.h',
  # Source files.
  'dart.cc',
  'dart_api_impl.cc',
  'object.cc',
  'raw_object.cc',
  'raw_object_snapshot.cc',
  'snapshot.cc',
  'symbols.cc',
]

def makeSnapshotHashString():
  vmhash = hashlib.md5()
  for vmfilename in VM_SNAPSHOT_FILES:
    vmfilepath = os.path.join(DART_DIR, 'runtime', 'vm', vmfilename)
    with open(vmfilepath) as vmfile:
      vmhash.update(vmfile.read())
  return vmhash.hexdigest()

def main():
  parser = argparse.ArgumentParser(description='Tests Dart snapshotting')
  parser.add_argument("--build-dir",
                      dest="build_dir",
                      metavar="<build-directory>",
                      type=str,
                      required=True,
                      help="The directory containing the Mojo build.")
  args = parser.parse_args()
  dart_snapshotter = os.path.join(args.build_dir, 'dart_snapshotter')
  package_root = os.path.join(args.build_dir, 'gen', 'dart-pkg', 'packages')
  main_dart = os.path.join(
      args.build_dir, 'gen', 'dart-pkg', 'mojo_dart_hello', 'lib', 'main.dart')
  snapshot = tempfile.mktemp()

  if not os.path.isfile(dart_snapshotter):
    print "file not found: " + dart_snapshotter
    return 1
  subprocess.check_call([
    dart_snapshotter,
    main_dart,
    '--package-root=%s' % package_root,
    '--snapshot=%s' % snapshot,
  ])
  if not os.path.isfile(snapshot):
    return 1

  expected_hash = makeSnapshotHashString()
  actual_hash = ""
  with open(snapshot) as snapshot_file:
    snapshot_file.seek(20)
    actual_hash = snapshot_file.read(32)
  if not actual_hash == expected_hash:
    print ('wrong hash: actual = %s, expected = %s'
           % (actual_hash, expected_hash))
    return 1
  return 0

if __name__ == '__main__':
  sys.exit(main())
