#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

""" Resolve a dart third_party library dependency by returning the path to an
existing downloaded version one of a few possible subdirectories under
//third_party. Some of these pre-downloaded libraries may be directly downloaded
via a //flutter/DEPS entry. Others may be bundled with the Dart SDK, in one of
its provided libraries or its third_party packages.
"""

import argparse
import json
import yaml
import os
import sys
import pkg_resources


def find_package(root, local_paths, package, version):
    """Return the package target if found with at least this version"""
    needed_version = pkg_resources.parse_version(version)
    for local_path in local_paths:
        package_path = os.path.join(local_path, package)
        pubspec_yaml = os.path.join(root, package_path, 'pubspec.yaml')
        if os.path.exists(pubspec_yaml):
            with open(pubspec_yaml) as yaml_file:
                pubspec = yaml.safe_load(yaml_file)
                found_version = pkg_resources.parse_version(pubspec['version'])
                if found_version >= needed_version:
                    return "//" + package_path
    return None


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        '--ignore-missing',
        action='store_true',
        help=('Return a success exit status, with all matched dart libraries, '
              'even if one or more matches were not found'))
    parser.add_argument(
        '--root',
        help='Path to the flutter engine src root',
        required=True)
    parser.add_argument(
        '--target',
        help='The name of the target that consolidates the derived deps',
        required=True)
    parser.add_argument(
        '--local-path',
        help=('A parent directory of pre-existing third_party dart libraries '
              '(multiple --local-path arguments allowed)'),
        action='append',
        dest='local_paths',
        required=True)

    (args, versioned_dart_packages) = parser.parse_known_args()

    assert os.path.exists(args.root)

    for path in args.local_paths:
        assert os.path.isdir(os.path.join(args.root, path))

    if len(versioned_dart_packages) > 0:
        assert len(versioned_dart_packages) % 2 == 0, (
            'Each third_party_dep package must be accompanied by a version')

    dart_package_paths = []
    it = iter(versioned_dart_packages)
    for item in it:
        (package, version) = item, next(it)
        path = find_package(args.root, args.local_paths, package, version)
        if path is not None:
            dart_package_paths.append(path)
        else:
            print(
                'No package found for %s with version %s' % (package, version),
                file=sys.stderr)
            if not args.ignore_missing:
                return 1

    json.dump(dart_package_paths, sys.stdout)

    return 0


if __name__ == '__main__':
    sys.exit(main())
