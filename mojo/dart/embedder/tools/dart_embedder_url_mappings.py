#!/usr/bin/python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script scans a directory tree for any .mojom files and outputs a
# list of url_mapping command line arguments for embedder-package: imports.
# These url_mapping arguments can be passed to gen_snapshot.

# an example output line:
# --url_mapping=dart:_mojom/mojo/service.mojom.dart, \
# /.../src/out/Debug/gen/dart_embedder_packages/mojo/service.mojom.dart

import argparse
import os
import sys

def scan(package_root, directory, mapped_to):
  for dirname, _, filenames in os.walk(directory):
    # Ignore tests.
    if dirname.endswith('tests'):
      continue;
    # filter for .mojom files.
    filenames = [f for f in filenames if f.endswith('.mojom')]
    for f in filenames:
      path = os.path.join(mapped_to, f)
      # Append .dart.
      path += '.dart'
      print('--url_mapping=dart:_' + path + ',' +
            os.path.join(package_root, path))

def main(args):
  parser = argparse.ArgumentParser(
      description='Generates --url_mapping arguments suitable for gen_snapshot')
  parser.add_argument('package_directory_root',
                      metavar='package_directory_root',
                      help='Path to directory containing target .dart '
                           'files.')
  parser.add_argument('packages',
                      metavar='packages',
                      nargs='+',
                      help='Paths to package(s) directories.')
  args = parser.parse_args()
  package_root = os.path.abspath(args.package_directory_root)
  packages = args.packages
  for package in packages:
    mapping = package.split(',', 1)
    directory = os.path.abspath(mapping[0])
    mapped_to = mapping[1]
    scan(package_root, directory, mapped_to)

if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
