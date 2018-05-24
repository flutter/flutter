#!/usr/bin/env python
# Copyright 2018 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script generates .packages file for frontend server from
# Dart SDKs .packages file located in third_party/dart/.packages

import os
import shutil

DOT_PACKAGES = '.packages'
FRONTEND_SERVER_DIR = os.getcwd()
SRC_DIR = os.path.dirname(os.path.dirname(FRONTEND_SERVER_DIR))
DART_PACKAGES_FILE = os.path.join(SRC_DIR, 'third_party', 'dart', DOT_PACKAGES)

with open(DOT_PACKAGES, 'w') as packages:
  with open(DART_PACKAGES_FILE, 'r') as dart_packages:
    for line in dart_packages:
      if line.startswith('#'):
        packages.write(line)
      else:
        [package, path] = line.split(':', 1)
        packages.write('%s:../../third_party/dart/%s' % (package, path))
  packages.write('frontend_server:./lib\n')
  packages.write('flutter_kernel_transformers:../flutter_kernel_transformers/lib\n')
