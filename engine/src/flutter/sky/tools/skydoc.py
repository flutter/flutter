#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import subprocess
import sys

from skypy.url_mappings import URLMappings

SKY_TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
SKY_ROOT = os.path.dirname(SKY_TOOLS_DIR)
SRC_ROOT = os.path.dirname(SKY_ROOT)

DARTDOC = 'dartdoc'

def main():
    try:
        subprocess.check_output([DARTDOC, '--version'])
    except:
        print 'Cannot find "dartdoc". Did you run `pub global activate dartdoc` ?'
        return 1

    parser = argparse.ArgumentParser(description='Sky Documentation Generator')
    parser.add_argument('build_dir', type=str, help='Path to build output')
    args = parser.parse_args()

    build_dir = os.path.abspath(args.build_dir)
    url_mappings = URLMappings(SRC_ROOT, build_dir)

    packages_root = os.path.join(build_dir, 'gen/dart-pkg/packages')
    sky_package = os.path.join(build_dir, 'gen/dart-pkg/sky')
    doc_dir = os.path.join(build_dir, 'gen/dart-pkg/sky/doc')

    if not os.path.exists(packages_root):
        print 'Cannot find Dart pacakges at "%s".' % packages_root
        print 'Did you run `ninja -C %s sky` ?' % os.path.relpath(build_dir, os.getcwd())
        return 1

    analyzer_args = [
        DARTDOC,
        '--package-root', packages_root,
        '--input', sky_package,
        '--output', doc_dir,
    ] + url_mappings.as_args
    subprocess.check_call(analyzer_args)

if __name__ == '__main__':
    sys.exit(main())
