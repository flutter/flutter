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
WORKBENCH_ROOT = os.path.join(SRC_ROOT, 'sky', 'packages', 'workbench')

DARTDOC = 'dartdoc'


def main():
    try:
        subprocess.check_output(['pub', 'global', 'run', DARTDOC, '--version'])
    except:
        print 'Cannot find "dartdoc". Did you run `pub global activate dartdoc` ?'
        return 1

    parser = argparse.ArgumentParser(description='Sky Documentation Generator')
    parser.add_argument('build_dir', type=str, help='Path to build output')
    parser.add_argument('--open', action='store_true',
         help='Open docs after building.')
    args = parser.parse_args()

    build_dir = os.path.abspath(args.build_dir)

    sky_package = os.path.join(SRC_ROOT, 'sky/packages/sky')
    doc_dir = os.path.join(build_dir, 'gen/dart-pkg/sky/doc')

    analyzer_args = [
        'pub',
        'global',
        'run',
        DARTDOC,
        '--input', sky_package,
        '--output', doc_dir
    ]
    subprocess.check_call(analyzer_args)

    if args.open:
        webbrowser.open(os.path.join(doc_dir, 'index.html'))


if __name__ == '__main__':
    sys.exit(main())
