#!/usr/bin/env python
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import shutil
import sys

# The list of packages copied from the Dart SDK.
PACKAGES = [
  "vm",
  "build_integration",
  "kernel",
  "front_end",
  "dev_compiler",
  "flutter_frontend_server",
  "frontend_server",
  "dev_compiler",
]

VM_PUBSPEC = r'''name: vm
version: 0.0.1
environment:
  sdk: ">=2.2.2 <3.0.0"

dependencies:
  dev_compiler: any
  front_end: any
  kernel: any
  meta: any
  build_integration: any
'''

BUILD_INTEGRATION_PUBSPEC = r'''name: build_integration
version: 0.0.1
environment:
  sdk: ">=2.2.2 <3.0.0"

dependencies:
  front_end: any
  meta: any
'''

FLUTTER_FRONTEND_SERVER_PUBSPEC = r'''name: flutter_frontend_server
version: 0.0.1
environment:
  sdk: ">=2.2.2 <3.0.0"

dependencies:
  args: any
  path: any
  vm: any
'''

KERNEL_PUBSPEC = r'''name: kernel
version: 0.0.1
environment:
  sdk: '>=2.2.2 <3.0.0'

dependencies:
  args: any
  meta: any
'''

FRONT_END_PUBSPEC = r'''name: front_end
version: 0.0.1
environment:
  sdk: '>=2.2.2 <3.0.0'
dependencies:
  kernel: any
  package_config: any
  meta: any
'''

DEV_COMPILER_PUBSPEC = r'''name: dev_compiler
version: 0.0.1
environment:
  sdk: '>=2.2.2 <3.0.0'
dependencies:
  analyzer: any
  bazel_worker: any
  build_integration: any
  cli_util: any
  source_maps: any
'''

FRONTEND_SERVER_PUBSPEC = r'''name: frontend_server
version: 0.0.1
environment:
  sdk: '>=2.2.2 < 3.0.0'
dependencies:
  build_integration: any
  vm: any
  dev_compiler: any
  front_end: any
  kernel: any
  args: any
'''

PUBSPECS = {
  'vm': VM_PUBSPEC,
  'build_integration': BUILD_INTEGRATION_PUBSPEC,
  'flutter_frontend_server': FLUTTER_FRONTEND_SERVER_PUBSPEC,
  'kernel': KERNEL_PUBSPEC,
  'front_end': FRONT_END_PUBSPEC,
  'dev_compiler': DEV_COMPILER_PUBSPEC,
  'frontend_server': FRONTEND_SERVER_PUBSPEC,
}

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('--frontend-server', type=str, dest='frontend', action='store')
  parser.add_argument('--input-root', type=str, dest='input', action='store')
  parser.add_argument('--output-root', type=str, dest='output', action='store')

  args = parser.parse_args()
  for package in PACKAGES:
    base = args.input
    # Handle different path for frontend_server
    if package == 'flutter_frontend_server':
      base = args.frontend
    package_root = os.path.join(base, package)
    for root, directories, files in os.walk(package_root):
      # We only care about actual source files, not generated code or tests.
      for skip_dir in ['.git', 'gen', 'test']:
        if skip_dir in directories:
          directories.remove(skip_dir)

      # Ensure we have a dest directory
      if not os.path.isdir(os.path.join(args.output, package)):
        os.makedirs(os.path.join(args.output, package))

      for filename in files:
        if filename.endswith('.dart') and not filename.endswith('_test.dart'):
          destination_file = os.path.join(args.output, package,
                                          os.path.relpath(os.path.join(root, filename), start=package_root))
          parent_path = os.path.abspath(os.path.join(destination_file, os.pardir))
          if not os.path.isdir(parent_path):
            os.makedirs(parent_path)
          shutil.copyfile(os.path.join(root, filename), destination_file)

    # Write the overriden pubspec for each package.
    pubspec_file = os.path.join(args.output, package, 'pubspec.yaml')
    with open(pubspec_file, 'w+') as output_file:
      output_file.write(PUBSPECS[package])

if __name__ == '__main__':
  sys.exit(main())
