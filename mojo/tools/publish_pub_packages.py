#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# See https://github.com/domokit/mojo/wiki/Release-process

import argparse
import distutils.util
import os
import subprocess
import sys
import tempfile

MOJO_TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
SRC_ROOT = os.path.dirname(os.path.dirname(MOJO_TOOLS_DIR))
DART_SDK = os.path.join(SRC_ROOT, 'third_party', 'dart-sdk', 'dart-sdk', 'bin')
PUB = os.path.join(DART_SDK, 'pub')

PACKAGES = [
  'mojo',
  'mojom',
  'mojo_services',
]

CONFIRM = """This tool is destructive and will revert your current branch to
origin/master among other things.  Are you sure you wish to continue?"""


def run(cwd, args):
    print 'RUNNING:', ' '.join(args), 'IN:', cwd
    subprocess.check_call(args, cwd=cwd)


def confirm(prompt):
    user_input = raw_input("%s (y/N) " % prompt)
    try:
        return distutils.util.strtobool(user_input) == 1
    except ValueError:
        return False


def main():
    parser = argparse.ArgumentParser(description='Deploy!')
    parser.parse_args()

    if not confirm(CONFIRM):
        print "Aborted."
        return 1

    run(SRC_ROOT, ['git', 'fetch', 'origin'])
    run(SRC_ROOT, ['git', 'reset', 'origin/master', '--hard'])
    run(SRC_ROOT, ['gclient', 'sync'])

    run(SRC_ROOT, ['mojo/tools/mojob.py', 'gn', '--android', '--release'])
    run(SRC_ROOT, ['ninja', '-C', 'out/android_Release'])

    package_root = tempfile.mkdtemp(prefix='pub_packages-')

    run(SRC_ROOT, [
        'mojo/tools/prepare_pub_packages.py',
        '--out-dir',
        package_root,
        'out',
    ])

    for package in PACKAGES:
        package_dir = os.path.join(package_root, package)
        print "PACKAGE", package_dir, "PUB", PUB
        run(package_dir, [PUB, 'publish', '--force'])


if __name__ == '__main__':
    sys.exit(main())
