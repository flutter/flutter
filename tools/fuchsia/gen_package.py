#!/usr/bin/env python
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
""" Genrate a Fuchsia FAR Archive from an asset manifest and a signing key.
"""

import argparse
import collections
import json
import os
import subprocess
import sys


# Generates the manifest and returns the file.
def GenerateManifest(package_dir):
  full_paths = []
  for root, dirs, files in os.walk(package_dir):
    for f in files:
      common_prefix = os.path.commonprefix([root, package_dir])
      rel_path = os.path.relpath(os.path.join(root, f), common_prefix)
      from_package = os.path.abspath(os.path.join(package_dir, rel_path))
      full_paths.append('%s=%s' % (rel_path, from_package))
  parent_dir = os.path.abspath(os.path.join(package_dir, os.pardir))
  manifest_file_name = os.path.basename(package_dir) + '.manifest'
  manifest_path = os.path.join(parent_dir, manifest_file_name)
  with open(manifest_path, 'w') as f:
    for item in full_paths:
      f.write("%s\n" % item)
  return manifest_path


def CreateFarPackage(pm_bin, package_dir, signing_key, dst_dir):
  manifest_path = GenerateManifest(package_dir)

  pm_command_base = [
      pm_bin, '-m', manifest_path, '-k', signing_key, '-o', dst_dir
  ]

  # Build the package
  subprocess.check_call(pm_command_base + ['build'])

  # Archive the package
  subprocess.check_call(pm_command_base + ['archive'])

  return 0


def main():
  parser = argparse.ArgumentParser()

  parser.add_argument('--pm-bin', dest='pm_bin', action='store', required=True)
  parser.add_argument(
      '--package-dir', dest='package_dir', action='store', required=True)
  parser.add_argument(
      '--signing-key', dest='signing_key', action='store', required=True)
  parser.add_argument(
      '--manifest-file', dest='manifest_file', action='store', required=True)

  args = parser.parse_args()

  assert os.path.exists(args.pm_bin)
  assert os.path.exists(args.package_dir)
  assert os.path.exists(args.signing_key)
  assert os.path.exists(args.manifest_file)

  pm_command_base = [
      args.pm_bin,
      '-o',
      args.package_dir,
      '-k',
      args.signing_key,
      '-m',
      args.manifest_file,
  ]

  # Build the package
  subprocess.check_call(pm_command_base + ['build'])

  # Archive the package
  subprocess.check_call(pm_command_base + ['archive'])

  return 0


if __name__ == '__main__':
  sys.exit(main())
