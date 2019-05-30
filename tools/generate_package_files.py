#!/usr/bin/env python
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script generates .packages file for frontend_server and
# flutter_kernel_transformers from Dart SDKs .packages file located in
# third_party/dart/.packages

import os
import shutil

ALL_PACKAGES = {
  'frontend_server': ['flutter_kernel_transformers'],
  'flutter_kernel_transformers': [],
}

SRC_DIR = os.getcwd()

DOT_PACKAGES = '.packages'
DART_PACKAGES_FILE = os.path.join(SRC_DIR, 'third_party', 'dart', DOT_PACKAGES)

# Generate .packages file in the given package.
def GeneratePackages(package, local_deps):
  with open(os.path.join('flutter', package, DOT_PACKAGES), 'w') as packages:
    with open(DART_PACKAGES_FILE, 'r') as dart_packages:
      for line in dart_packages:
        if line.startswith('#'):
          packages.write(line)
        else:
          [name, path] = line.split(':', 1)
          packages.write('%s:../../third_party/dart/%s' % (name, path))
    packages.write('%s:./lib\n' % (package))
    for other_package in local_deps:
      packages.write('%s:../%s/lib\n' % (other_package, other_package))

for package, local_deps in ALL_PACKAGES.iteritems():
  GeneratePackages(package, local_deps)
