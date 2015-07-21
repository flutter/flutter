#!/usr/bin/env python
#
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Utility for dart_pkg and dart_pkg_app rules"""

import argparse
import errno
import json
import os
import shutil
import sys

# Disable lint check for finding modules:
# pylint: disable=F0401

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "bindings/pylib"))

from mojom.parse.parser import Parse
from mojom.parse.translate import Translate

USE_LINKS = sys.platform != "win32"


def mojom_dart_filter(path):
    if os.path.isdir(path):
        return True
    # Don't include all .dart, just .mojom.dart.
    return path.endswith('.mojom.dart')


def dart_filter(path):
    if os.path.isdir(path):
        return True
    _, ext = os.path.splitext(path)
    # .dart includes '.mojom.dart'
    return ext == '.dart'


def mojom_filter(path):
    if os.path.isdir(path):
        return True
    _, ext = os.path.splitext(path)
    return ext == '.mojom'


def ensure_dir_exists(path):
    abspath = os.path.abspath(path)
    if not os.path.exists(abspath):
        os.makedirs(abspath)


def has_pubspec_yaml(paths):
    for path in paths:
        _, filename = os.path.split(path)
        if 'pubspec.yaml' == filename:
            return True
    return False


def link(from_root, to_root):
    ensure_dir_exists(os.path.dirname(to_root))
    if os.path.exists(to_root):
      os.unlink(to_root)
    try:
        os.symlink(from_root, to_root)
    except OSError as e:
        if e.errno == errno.EEXIST:
            pass


def copy(from_root, to_root, filter_func=None):
    if not os.path.exists(from_root):
        return
    if os.path.isfile(from_root):
        ensure_dir_exists(os.path.dirname(to_root))
        shutil.copy(from_root, to_root)
        return

    ensure_dir_exists(to_root)

    for root, dirs, files in os.walk(from_root):
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
            shutil.copy(from_path, to_path)

        dirs[:] = filter(wrapped_filter, dirs)


def copy_or_link(from_root, to_root, filter_func=None):
    if USE_LINKS:
        link(from_root, to_root)
    else:
        copy(from_root, to_root, filter_func)


def remove_if_exists(path):
    try:
        os.remove(path)
    except OSError as e:
        if e.errno != errno.ENOENT:
            raise

def list_files(from_root, filter_func=None):
    file_list = []
    for root, dirs, files in os.walk(from_root):
        # filter_func expects paths not names, so wrap it to make them absolute.
        wrapped_filter = None
        if filter_func:
            wrapped_filter = lambda name: filter_func(os.path.join(root, name))
        for name in filter(wrapped_filter, files):
            path = os.path.join(root, name)
            file_list.append(path)
        dirs[:] = filter(wrapped_filter, dirs)
    return file_list


def remove_broken_symlink(path):
    try:
        link_path = os.readlink(path)
    except OSError as e:
        # Path was not a symlink.
        if e.errno == errno.EINVAL:
            pass
    else:
        if not os.path.exists(link_path):
            os.unlink(path)


def remove_broken_symlinks(root_dir):
    for current_dir, _, child_files in os.walk(root_dir):
        for filename in child_files:
            path = os.path.join(current_dir, filename)
            remove_broken_symlink(path)


def mojom_path(filename):
    with open(filename) as f:
        source = f.read()
    tree = Parse(source, filename)
    _, name = os.path.split(filename)
    mojom = Translate(tree, name)
    elements = mojom['namespace'].split('.')
    elements.append("%s" % mojom['name'])
    return os.path.join(*elements)


def main():
    parser = argparse.ArgumentParser(description='Generate a dart-pkg')
    parser.add_argument('--package-name',
                        action='store',
                        type=str,
                        metavar='package_name',
                        help='Name of package',
                        required=True)
    parser.add_argument('--gen-directory',
                        metavar='gen_directory',
                        help="dart-gen directory",
                        required=True)
    parser.add_argument('--pkg-directory',
                        metavar='pkg_directory',
                        help='Directory where dart_pkg should go',
                        required=True)
    parser.add_argument('--package-root',
                        metavar='package_root',
                        help='packages/ directory',
                        required=True)
    parser.add_argument('--stamp-file',
                        metavar='stamp_file',
                        help='timestamp file',
                        required=True)
    parser.add_argument('--package-sources',
                        metavar='package_sources',
                        help='Package sources',
                        nargs='+')
    parser.add_argument('--mojom-sources',
                        metavar='mojom_sources',
                        help='.mojom and .mojom.dart sources',
                        nargs='*',
                        default=[])
    parser.add_argument('--sdk-ext-directories',
                        metavar='sdk_ext_directories',
                        help='Directory containing .dart sources',
                        nargs='*',
                        default=[])
    parser.add_argument('--sdk-ext-files',
                        metavar='sdk_ext_files',
                        help='List of .dart files that are part of of sdk_ext.',
                        nargs='*',
                        default=[])
    parser.add_argument('--sdk-ext-mappings',
                        metavar='sdk_ext_mappings',
                        help='Mappings for SDK extension libraries.',
                        nargs='*',
                        default=[])
    args = parser.parse_args()

    # We must have a pubspec.yaml.
    assert has_pubspec_yaml(args.package_sources)

    target_dir = os.path.join(args.pkg_directory, args.package_name)
    lib_path = os.path.join(target_dir, "lib")

    mappings = {}
    for mapping in args.sdk_ext_mappings:
        library, path = mapping.split(',', 1)
        mappings[library] = '../sdk_ext/%s' % path

    sdkext_path = os.path.join(lib_path, '_sdkext')
    if mappings:
        ensure_dir_exists(lib_path)
        with open(sdkext_path, 'w') as stream:
            json.dump(mappings, stream, sort_keys=True,
                      indent=2, separators=(',', ': '))
    else:
        remove_if_exists(sdkext_path)

    # Copy or symlink package sources into pkg directory.
    common_source_prefix = os.path.commonprefix(args.package_sources)
    for source in args.package_sources:
        relative_source = os.path.relpath(source, common_source_prefix)
        target = os.path.join(target_dir, relative_source)
        copy_or_link(source, target)

    # Copy sdk-ext sources into pkg directory
    sdk_ext_dir = os.path.join(target_dir, 'sdk_ext')
    for directory in args.sdk_ext_directories:
        sdk_ext_sources = list_files(directory, dart_filter)
        common_prefix = os.path.commonprefix(sdk_ext_sources)
        for source in sdk_ext_sources:
            relative_source = os.path.relpath(source, common_prefix)
            target = os.path.join(sdk_ext_dir, relative_source)
            copy_or_link(source, target)
    for source in args.sdk_ext_files:
        common_prefix = os.path.commonprefix(args.sdk_ext_files)
        relative_source = os.path.relpath(source, common_prefix)
        target = os.path.join(sdk_ext_dir, relative_source)
        copy_or_link(source, target)

    lib_mojom_path = os.path.join(lib_path, "mojom")

    # Copy generated mojom.dart files.
    generated_mojom_lib_path = os.path.join(args.gen_directory, "mojom/lib")
    for mojom_source_path in args.mojom_sources:
        path = mojom_path(mojom_source_path)
        source_path = '%s.dart' % os.path.join(generated_mojom_lib_path, path)
        target_path = '%s.dart' % os.path.join(lib_mojom_path, path)
        copy(source_path, target_path)

    # Symlink packages/
    package_path = os.path.join(args.package_root, args.package_name)
    link(lib_path, package_path)

    # Remove any broken symlinks in target_dir and package root.
    remove_broken_symlinks(target_dir)
    remove_broken_symlinks(args.package_root)

    # Write stamp file.
    with open(args.stamp_file, 'w'):
        pass

if __name__ == '__main__':
    sys.exit(main())
