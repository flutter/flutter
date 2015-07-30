#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import subprocess
import sys

SKY_BUILD_DIR = os.path.dirname(os.path.abspath(__file__))
SRC_ROOT = os.path.dirname(os.path.dirname(SKY_BUILD_DIR))
WORKBENCH = os.path.join(SRC_ROOT, 'sky', 'packages', 'workbench')
DART_SDK = os.path.join(SRC_ROOT, 'third_party', 'dart-sdk', 'dart-sdk', 'bin')
PUB = os.path.join(DART_SDK, 'pub')
PUB_CACHE = os.path.join(SRC_ROOT, "dart-pub-cache")

def main():
    parser = argparse.ArgumentParser(description='Packaging tool for Sky apps')
    parser.add_argument('--touch', type=str)
    args = parser.parse_args()

    env = os.environ.copy()
    env["PUB_CACHE"] = PUB_CACHE
    subprocess.check_call([PUB, 'run', 'sky:init'], cwd=WORKBENCH, env=env)

    if args.touch:
        with open(os.path.abspath(args.touch), 'w') as f:
            pass

if __name__ == '__main__':
    sys.exit(main())
