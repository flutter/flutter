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

  parser.add_argument('--main-dart', type=str, required=True,
                      help='The main.dart file to use')

  parser.add_argument('--url-mapping', type=str, action='append',
                      help='The main.dart file to use')
  parser.add_argument('--entry-points-manifest', type=str, action='append',
                      help='The main.dart file to use')

  parser.add_argument('--packages', type=str, required=True,
                      help='The package map to use')
  parser.add_argument('--assembly', type=str, required=True,
                      help='Where to output application assembly')
  parser.add_argument('--depfile', type=str, required=True,
                      help='Where to output dependency information')
  parser.add_argument('--root-build-dir', type=str, required=True,
                      help='The root build dir for --depfile and --snapshot')
  parser.add_argument('--checked', default=False, action='store_true',
                      help='Enable checked mode')

  args = parser.parse_args()

  cmd = [
    args.snapshotter_path,
    "--enable_mirrors=false",
    "--await_is_keyword",
    '--snapshot_kind=app-aot-assembly',
    '--packages=%s' % args.packages,
    '--assembly=%s' % args.assembly,
    '--dependencies=%s' % args.depfile,
  ]
  for url_mapping in args.url_mapping:
    cmd.append("--url_mapping=" + url_mapping)
  for entry_points_manifest in args.entry_points_manifest:
    cmd.append("--embedder_entry_points_manifest=" + entry_points_manifest)
  if args.checked:
    cmd.append('--enable_asserts')
    cmd.append('--enable_type_checks')
    cmd.append('--error_on_bad_type')
    cmd.append('--error_on_bad_override')
  cmd.append(args.main_dart)

  result = subprocess.call(cmd, cwd=args.root_build_dir)
  if result != 0:
    print("Command failed: '%s'" % (" ".join(cmd)))

  return result


if __name__ == '__main__':
  sys.exit(main())
