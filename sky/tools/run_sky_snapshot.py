#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import subprocess
import sys

SKY_TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
SRC_ROOT = os.path.dirname(os.path.dirname(SKY_TOOLS_DIR))
WORKBENCH = os.path.join(SRC_ROOT, 'sky', 'packages', 'workbench')

def main():
    parser = argparse.ArgumentParser(description='Builds a Dart snapshot file')
    parser.add_argument('--main', type=str)
    parser.add_argument('--compiler', type=str)
    parser.add_argument('--package-root', type=str)
    parser.add_argument('--snapshot', type=str)
    args = parser.parse_args()

    command = [
        os.path.abspath(args.compiler),
        '--package-root=%s' % os.path.abspath(args.package_root),
        '--snapshot=%s' % os.path.abspath(args.snapshot),
        os.path.abspath(args.main),
    ]

    subprocess.check_call(command, cwd=WORKBENCH)

if __name__ == '__main__':
    sys.exit(main())
