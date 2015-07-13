#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Prepare release script.
#
# 1) Bump versions:
# sky/sdk/example/demo_launcher/apk/AndroidManifest.xml
# mojo/dart/mojo_services/pubspec.yaml
# mojo/dart/mojom/pubspec.yaml
# mojo/public/dart/pubspec.yaml
# sky/sdk/pubspec.yaml
#
# 2) Update change logs:
# mojo/dart/mojo_services/CHANGELOG.md
# mojo/dart/mojom/CHANGELOG.md
# mojo/public/dart/CHANGELOG.md
# sky/sdk/CHANGELOG.md
#
# 3) Make a commit, upload it, land it.
#
# 4) Run this script.
#

import argparse
import os
import subprocess
import sys
import distutils.util

DEFAULT_MOJO_ROOT = '/src/mojo/src'
DEFAULT_SKY_SDK_ROOT = '/src/sky_sdk'
DEFAULT_DEMO_SITE_ROOT = '/src/domokit.github.io'
CONFIRM_MESSAGE = """This tool is destructive and will revert your current branch to
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
    parser.add_argument('--mojo-root',
                        action='store',
                        type=str,
                        metavar='mojo_root',
                        help='Path to mojo/src',
                        default=DEFAULT_MOJO_ROOT)
    parser.add_argument('--sky-sdk-root',
                        action='store',
                        type=str,
                        metavar='sky_sdk_root',
                        help='Path to sky_sdk',
                        default=DEFAULT_SKY_SDK_ROOT)
    parser.add_argument('--demo-site-root',
                        action='store',
                        type=str,
                        metavar='demo_site_root',
                        help='Path to domokit.github.io',
                        default=DEFAULT_DEMO_SITE_ROOT)
    args = parser.parse_args()

    if not confirm(CONFIRM_MESSAGE):
        print "Aborted."
        return 1

    mojo_root = os.path.abspath(os.path.expanduser(args.mojo_root))
    sky_sdk_root = os.path.abspath(os.path.expanduser(args.sky_sdk_root))
    demo_site_root = os.path.abspath(os.path.expanduser(args.demo_site_root))

    # Derived paths:
    dart_sdk_root = os.path.join(mojo_root, 'third_party/dart-sdk/dart-sdk')
    pub_path = os.path.join(dart_sdk_root, 'bin/pub')
    packages_root = os.path.join(sky_sdk_root, 'packages')

    run(mojo_root, ['git', 'pull', '--rebase'])
    run(mojo_root, ['gclient', 'sync'])
    run(mojo_root, ['mojo/tools/mojob.py', 'gn', '--android', '--release'])
    run(mojo_root, ['mojo/tools/mojob.py', 'build', '--android', '--release'])
    # Run tests?

    run(sky_sdk_root, ['git', 'fetch'])
    run(sky_sdk_root, ['git', 'reset', '--hard', 'origin/master'])
    run(mojo_root, [
        'sky/tools/deploy_sdk.py',
        '--non-interactive',
        '--commit',
        sky_sdk_root
    ])
    # tag for version?

    run(demo_site_root, ['git', 'fetch'])
    run(demo_site_root, ['git', 'reset', '--hard', 'origin/master'])
    run(mojo_root, ['mojo/tools/deploy_domokit_site.py', demo_site_root])
    # tag for version?

    for package in os.listdir(packages_root):
        package_path = os.path.join(packages_root, package)
        if not os.path.isdir(package_path):
            continue
        run(package_path, [pub_path, 'publish', '--force'])

    run(sky_sdk_root, ['git', 'push'])
    run(demo_site_root, ['git', 'push'])


if __name__ == '__main__':
    sys.exit(main())