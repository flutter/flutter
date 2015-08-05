#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import subprocess
import sys
import webbrowser
from skypy.url_mappings import URLMappings

SKY_TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
SKY_ROOT = os.path.dirname(SKY_TOOLS_DIR)
SRC_ROOT = os.path.dirname(SKY_ROOT)
WORKBENCH_ROOT = os.path.join(SRC_ROOT, 'sky', 'packages', 'workbench')

DARTDOC = 'dartdoc'


def main():
    try:
        subprocess.check_output([DARTDOC, '--version'])
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

    # dartdoc doesn't understand sdk_ext yet, so we still need url_mappings:
    # https://github.com/dart-lang/dartdoc/issues/763
    url_mappings = URLMappings(SRC_ROOT, build_dir)

    analyzer_args = [
        DARTDOC,
        '--input', sky_package,
        '--output', doc_dir,
        # dartdoc appears to ignore --package-root:
        # https://github.com/dart-lang/dartdoc/issues/766
        '--package-root', os.path.join(WORKBENCH_ROOT, 'packages')
    ] + url_mappings.as_args
    subprocess.check_call(analyzer_args)

    if args.open:
        webbrowser.open(os.path.join(doc_dir, 'index.html'))


if __name__ == '__main__':
    sys.exit(main())
