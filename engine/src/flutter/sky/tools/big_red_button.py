#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# See https://github.com/domokit/sky_engine/wiki/Release-process

import argparse
import os
import subprocess
import sys
import distutils.util


CONFIRM_MESSAGE = """This tool is destructive and will revert your current branch to
origin/master among other things.  Are you sure you wish to continue?"""
DRY_RUN = False


def run(cwd, args):
    print 'RUNNING:', ' '.join(args), 'IN:', cwd
    if DRY_RUN:
        return
    subprocess.check_call(args, cwd=cwd)


def confirm(prompt):
    user_input = raw_input("%s (y/N) " % prompt)
    try:
        return distutils.util.strtobool(user_input) == 1
    except ValueError:
        return False


def main():
    parser = argparse.ArgumentParser(description='Deploy!')
    parser.add_argument('sky_engine_root', help='Path to sky_engine/src')
    parser.add_argument('sky_sdk_root', help='Path to sky_sdk')
    parser.add_argument('demo_site_root', help='Path to domokit.github.io')
    parser.add_argument('--dry-run', action='store_true', default=False,
        help='Just print commands w/o executing.')
    parser.add_argument('--no-pub-publish', dest='publish',
        action='store_false', default=True, help='Skip pub publish step.')
    args = parser.parse_args()

    global DRY_RUN
    DRY_RUN = args.dry_run

    if not args.dry_run and not confirm(CONFIRM_MESSAGE):
        print "Aborted."
        return 1

    sky_engine_root = os.path.abspath(os.path.expanduser(args.sky_engine_root))
    sky_sdk_root = os.path.abspath(os.path.expanduser(args.sky_sdk_root))
    demo_site_root = os.path.abspath(os.path.expanduser(args.demo_site_root))

    # Derived paths:
    dart_sdk_root = os.path.join(sky_engine_root, 'third_party/dart-sdk/dart-sdk')
    pub_path = os.path.join(dart_sdk_root, 'bin/pub')
    packages_root = os.path.join(sky_sdk_root, 'packages')

    run(sky_engine_root, ['git', 'pull', '--rebase'])
    run(sky_engine_root, ['gclient', 'sync'])
    run(sky_engine_root, ['sky/tools/gn', '--android', '--release'])
    # TODO(eseidel): We shouldn't use mojob anymore, it likely will break.
    run(sky_engine_root, ['mojo/tools/mojob.py', 'build', '--android', '--release'])
    # Run tests?

    run(sky_engine_root, [
        'sky/tools/deploy_sdk.py',
        '--non-interactive',
        sky_sdk_root
    ])
    # tag for version?

    run(demo_site_root, ['git', 'fetch'])
    run(demo_site_root, ['git', 'reset', '--hard', 'origin/master'])
    # TODO(eseidel): We should move this script back into sky/tools.
    run(sky_engine_root, ['mojo/tools/deploy_domokit_site.py', demo_site_root])
    # tag for version?

    if args.publish:
        package_path = os.path.join(packages_root, 'sky')
        run(package_path, [pub_path, 'publish', '--force'])

    run(demo_site_root, ['git', 'push'])


if __name__ == '__main__':
    sys.exit(main())
