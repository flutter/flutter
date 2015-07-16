#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Deploy domokit.github.io"""

# NOTE: Requires that download_material_design_icons to have been run from
# $build_dir/gen/dart-dpkg/sky.

import argparse
import logging
import os
import shutil
import subprocess

from mopy.paths import Paths


def git_revision():
    return subprocess.check_output(['git', 'rev-parse', 'HEAD']).strip()


def mojo_filter(path):
    if not os.path.isfile(path):
        return False
    _, ext = os.path.splitext(path)
    if ext != '.mojo':
        return False
    return 'apptests' not in os.path.basename(path)


def gen_filter(path):
    if os.path.isdir(path):
        return True
    _, ext = os.path.splitext(path)
    # Don't include all .dart, just .mojom.dart.
    return ext == '.sky' or path.endswith('.mojom.dart')


def examples_filter(path):
    if os.path.isdir(path):
        return True
    return 'packages' != os.path.basename(path)


def sky_or_dart_filter(path):
    if os.path.isdir(path):
        return True
    _, ext = os.path.splitext(path)
    # .dart includes '.mojom.dart'
    return ext == '.sky' or ext == '.dart'


def assets_filter(path):
    if os.path.isdir(path):
        return True
    if os.path.basename(os.path.dirname(path)) != 'drawable-xxhdpi':
        return False
    # We only use the 18 and 24s for now.
    return '18dp' in path or '24dp' in path


def packages_filter(path):
    if 'packages/sky/assets/material-design-icons/' in path:
        return assets_filter(path)
    if '.gitignore' in path:
        return False
    return True


def ensure_dir_exists(path):
    if not os.path.exists(path):
        os.makedirs(path)


def copy(from_root, to_root, filter_func=None, followlinks=False):
    assert os.path.exists(from_root), "%s does not exist!" % from_root
    if os.path.isfile(from_root):
        ensure_dir_exists(os.path.dirname(to_root))
        shutil.copy(from_root, to_root)
        return

    if os.path.exists(to_root):
        shutil.rmtree(to_root)
    os.makedirs(to_root)

    for root, dirs, files in os.walk(from_root, followlinks=followlinks):
        # filter_func expects paths not names, so wrap it to make them absolute.
        wrapped_filter = None
        if filter_func:
            wrapped_filter = lambda name: filter_func(os.path.join(root, name))

        for name in filter(wrapped_filter, files):
            from_path = os.path.join(root, name)
            root_rel_path = os.path.relpath(from_path, from_root)
            to_path = os.path.join(to_root, root_rel_path)
            to_dir = os.path.dirname(to_path)
            if not os.path.exists(to_dir):
                os.makedirs(to_dir)
            shutil.copyfile(from_path, to_path)

        dirs[:] = filter(wrapped_filter, dirs)


def main():
    logging.basicConfig(level=logging.WARN)
    parser = argparse.ArgumentParser(description='Deploy a new build of mojo.')
    parser.add_argument('deploy_root', type=str)
    args = parser.parse_args()

    # Always use android release?
    rel_build_dir = os.path.join('out', 'android_Release')
    build_dir = os.path.join(Paths().src_root, rel_build_dir)
    paths = Paths(build_dir=build_dir)
    dart_pkg_dir = os.path.join(paths.build_dir, 'gen', 'dart-pkg')
    sky_pkg_dir = os.path.join(dart_pkg_dir, 'sky')
    sky_pkg_lib_dir = os.path.join(sky_pkg_dir, 'lib')
    dart_pkg_packages_dir = os.path.join(dart_pkg_dir, 'packages')

    def deploy_path(rel_path):
        return os.path.join(args.deploy_root, rel_path)

    def src_path(rel_path):
        return os.path.join(paths.src_root, rel_path)

    # Verify that material-design-icons have been downloaded.
    icons_dir = os.path.join(dart_pkg_packages_dir,
                             'sky/assets/material-design-icons')
    if not os.path.isdir(icons_dir):
        print('NOTE: Running `download_material_design_icons` for you.');
        subprocess.check_call([
                os.path.join(sky_pkg_lib_dir, 'download_material_design_icons')
            ])

    # Copy sky/sdk/example into example/
    copy(src_path('sky/sdk/example'), deploy_path('example'), examples_filter)

    # Deep copy packages/. This follows symlinks and flattens them.
    packages_root = deploy_path('packages')
    copy(dart_pkg_packages_dir, packages_root, packages_filter, True)

    # Write out license.
    with open(deploy_path('LICENSES.sky'), 'w') as license_file:
        subprocess.check_call([src_path('tools/licenses.py'), 'credits'],
            stdout=license_file)

    # Run git commands.
    subprocess.check_call(['git', 'add', '.'], cwd=args.deploy_root)
    subprocess.check_call([
        'git', 'commit',
        '-m', '%s from %s' % (rel_build_dir, git_revision())
        ], cwd=args.deploy_root)


if __name__ == '__main__':
    main()
