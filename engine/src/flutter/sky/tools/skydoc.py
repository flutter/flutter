#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import subprocess
import sys
import webbrowser

SKY_TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
SKY_ROOT = os.path.dirname(SKY_TOOLS_DIR)
SRC_ROOT = os.path.dirname(SKY_ROOT)
WORKBENCH_DIR = os.path.join(SRC_ROOT, 'sky', 'packages', 'workbench')
SKY_PACKAGE = os.path.join(SRC_ROOT, 'sky', 'packages', 'sky')

DART_SDK = os.path.join(SRC_ROOT, 'third_party', 'dart-sdk', 'dart-sdk', 'bin')
DARTDOC = os.path.join(DART_SDK, 'dartdoc')
PUB_CACHE = os.path.join(SRC_ROOT, 'dart-pub-cache')

def main():
    parser = argparse.ArgumentParser(description='Sky Documentation Generator')
    parser.add_argument('--open', action='store_true',
         help='Open docs after building.')
    args = parser.parse_args()

    doc_dir = os.path.join(SKY_PACKAGE, 'doc')

    cmd = [
        DARTDOC,
        '--input', SKY_PACKAGE,
        '--output', doc_dir
    ]
    subprocess.check_call(cmd, cwd=WORKBENCH_DIR)

    if args.open:
        webbrowser.open(os.path.join(doc_dir, 'index.html'))


if __name__ == '__main__':
    sys.exit(main())
