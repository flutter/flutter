#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Prepares pub packages for upload."""

# NOTE: Requires the following build artifacts:
# *) out/Config/gen/dart-pkg
# *) out/Config/apks/
# By default Config is 'android_Release'

import argparse
import os
import shutil
import tempfile


def remove_empty_dirs(root_dir):
    for root, dirs, _ in os.walk(root_dir):
         for name in dirs:
             fname = os.path.join(root, name)
             if not os.listdir(fname):
                 os.removedirs(fname)


def copy_package(src_dir, dst_dir, ignore=None):
    # Remove existing destination directory.
    shutil.rmtree(dst_dir, True)
    shutil.copytree(src_dir, dst_dir, symlinks=False, ignore=ignore)


def install_mojo_license_and_authors_files(sdk_root, dst_dir):
    shutil.copy(os.path.join(sdk_root, 'LICENSE'), dst_dir)
    shutil.copy(os.path.join(sdk_root, 'AUTHORS'), dst_dir)


def main():
    parser = argparse.ArgumentParser(
        description='Prepare pub packages for upload')
    parser.add_argument('--config',
                        type=str,
                        default='android_Release')
    parser.add_argument('--sdk-root',
                        type=str,
                        default='.')
    parser.add_argument('--packages',
                        default=['mojo', 'mojom', 'mojo_services', 'sky'])
    parser.add_argument('--out-dir',
                        default=None)
    parser.add_argument('build_dir',
                        type=str)
    args = parser.parse_args()

    rel_build_dir = os.path.join(args.build_dir, args.config)
    build_dir = os.path.abspath(rel_build_dir)
    sdk_dir = os.path.abspath(args.sdk_root)
    print('Using SDK in %s' % sdk_dir)
    print('Using build in %s' % build_dir)

    preparing_sky_package = 'sky' in args.packages

    apks_dir = os.path.join(build_dir, 'apks')
    sky_apk_filename = 'SkyDemo.apk'
    sky_apk = os.path.join(apks_dir, sky_apk_filename)
    if preparing_sky_package and (not os.path.exists(sky_apk)):
        print('Required file %s not found.' % sky_apk)
        return -1

    temp_dir = args.out_dir
    if temp_dir:
        try:
            shutil.rmtree(temp_dir)
        except OSError:
            pass
        os.makedirs(temp_dir)
    else:
        # Create a temporary directory to copy files into.
        temp_dir = tempfile.mkdtemp(prefix='pub_packages-')

    print('Packages ready to be uploaded in %s' % temp_dir)

    # Copy packages
    dart_pkg_dir = os.path.join(build_dir, 'gen', 'dart-pkg')
    for package in args.packages:
        print('Preparing package %s' % package)
        src_dir = os.path.join(dart_pkg_dir, package)
        dst_dir = os.path.join(temp_dir, package)
        ignore = None
        # Special case 'mojom' package to not copy generated mojom.dart files.
        if package == 'mojom':
            ignore = shutil.ignore_patterns('*.mojom.dart')
        copy_package(src_dir, dst_dir, ignore)
        # Special case 'mojom' package to remove empty directories.
        if package == 'mojom':
            remove_empty_dirs(dst_dir)
        install_mojo_license_and_authors_files(sdk_dir, dst_dir)

    # Copy Sky apk.
    if preparing_sky_package:
        prepared_apks_dir = os.path.join(temp_dir, 'sky', 'apks')
        os.makedirs(prepared_apks_dir)
        shutil.copyfile(sky_apk,
                        os.path.join(prepared_apks_dir, sky_apk_filename))


if __name__ == '__main__':
    main()
