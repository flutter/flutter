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
DART_SDK = os.path.join(SRC_ROOT, 'third_party', 'dart-sdk', 'dart-sdk', 'bin')

def main():
    parser = argparse.ArgumentParser(description='Packaging tool for Sky apps')
    parser.add_argument('--manifest', type=str)
    parser.add_argument('--asset-base', type=str)
    parser.add_argument('--snapshot', type=str)
    parser.add_argument('-o', '--output-file', type=str)
    args = parser.parse_args()

    command = [
        os.path.join(DART_SDK, 'dart'),
        os.path.join(SKY_TOOLS_DIR, 'skyx', 'bin', 'skyx.dart'),
        '--asset-base', args.asset_base,
        '--snapshot', args.snapshot,
        '--output-file', args.output_file,
    ]

    if args.manifest:
        command += ['--manifest', args.manifest]

    subprocess.check_call(command)

if __name__ == '__main__':
    sys.exit(main())
