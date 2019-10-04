#!/usr/bin/env python
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
""" Gather all the fuchsia artifacts to a destination directory.
"""

import argparse
import errno
import json
import os
import platform
import shutil
import subprocess
import sys

_ARTIFACT_PATH_TO_DST = {
    'flutter_jit_runner': 'flutter_jit_runner',
    'icudtl.dat': 'data/icudtl.dat',
    'dart_runner': 'dart_runner',
    'flutter_patched_sdk': 'flutter_patched_sdk'
}


def EnsureParentExists(path):
  dir_name, _ = os.path.split(path)
  if not os.path.exists(dir_name):
    os.makedirs(dir_name)


def CopyPath(src, dst):
  try:
    EnsureParentExists(dst)
    shutil.copytree(src, dst)
  except OSError as exc:
    if exc.errno == errno.ENOTDIR:
      shutil.copy(src, dst)
    else:
      raise


def CreateMetaPackage(dst_root, far_name):
  meta = os.path.join(dst_root, 'meta')
  if not os.path.isdir(meta):
    os.makedirs(meta)
  content = {}
  content['name'] = far_name
  content['version'] = '0'
  package = os.path.join(meta, 'package')
  with open(package, 'w') as out_file:
    json.dump(content, out_file)


def GatherArtifacts(src_root, dst_root, create_meta_package=True):
  if not os.path.exists(dst_root):
    os.makedirs(dst_root)
  else:
    shutil.rmtree(dst_root)

  for src_rel, dst_rel in _ARTIFACT_PATH_TO_DST.iteritems():
    src_full = os.path.join(src_root, src_rel)
    dst_full = os.path.join(dst_root, dst_rel)
    if not os.path.exists(src_full):
      print 'Unable to find artifact: ', str(src_full)
      sys.exit(1)
    CopyPath(src_full, dst_full)

  if create_meta_package:
    CreateMetaPackage(dst_root, 'flutter_runner')


def main():
  parser = argparse.ArgumentParser()

  parser.add_argument(
      '--artifacts-root', dest='artifacts_root', action='store', required=True)
  parser.add_argument(
      '--dest-dir', dest='dst_dir', action='store', required=True)

  args = parser.parse_args()

  assert os.path.exists(args.artifacts_root)
  dst_parent = os.path.abspath(os.path.join(args.dst_dir, os.pardir))
  assert os.path.exists(dst_parent)

  GatherArtifacts(args.artifacts_root, args.dst_dir)
  return 0


if __name__ == '__main__':
  sys.exit(main())
