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
DART_SDK = os.path.join(SRC_ROOT, 'third_party', 'dart-sdk', 'dart-sdk', 'bin')

def main():
    parser = argparse.ArgumentParser(description='Packaging tool for Sky apps')
    parser.add_argument('--asset-base', type=str)
    parser.add_argument('--compiler', type=str)
    parser.add_argument('--main', type=str)
    parser.add_argument('--manifest', type=str)
    parser.add_argument('--output-file', type=str)
    parser.add_argument('--package-root', type=str)
    parser.add_argument('--snapshot', type=str)
    args = parser.parse_args()

    command = [
        os.path.join(DART_SDK, 'pub'),
        'run', 'sky_tools', 'build',
        '--asset-base', os.path.abspath(args.asset_base),
        '--compiler', os.path.abspath(args.compiler),
        '--main', os.path.abspath(args.main),
        '--output-file', os.path.abspath(args.output_file),
        '--package-root', os.path.abspath(args.package_root),
        '--snapshot', os.path.abspath(args.snapshot),
    ]

    if args.manifest:
        command += ['--manifest', os.path.abspath(args.manifest)]

    subprocess.check_call(command, cwd=WORKBENCH)

if __name__ == '__main__':
    sys.exit(main())
