#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import subprocess

FLUTTER_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def update(directory):
    packages = sorted(os.listdir(directory))
    for package in packages:
        package_dir = os.path.join(directory, package)
        if os.path.isdir(package_dir):
            print 'Updating', package, '...'
            subprocess.check_call(['pub', 'get'], cwd=package_dir)

update(os.path.join(FLUTTER_ROOT, 'packages'))
update(os.path.join(FLUTTER_ROOT, 'examples'))
