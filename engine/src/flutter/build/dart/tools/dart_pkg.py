#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Utility for dart_pkg and dart_pkg_app rules"""

import argparse
import errno
import json
import os
import shutil
import subprocess
import sys


def dart_filter(path):
  if os.path.isdir(path):
    return True
  _, ext = os.path.splitext(path)
  return ext == '.dart'


def ensure_dir_exists(path):
  abspath = os.path.abspath(path)
  if not os.path.exists(abspath):
    os.makedirs(abspath)


def has_pubspec_yaml(paths):
  for path in paths:
    _, filename = os.path.split(path)
    if filename == 'pubspec.yaml':
      return True
  return False


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
      wrapped_filter = lambda name, rt=root: filter_func(os.path.join(rt, name))

    for name in filter(wrapped_filter, files):
      from_path = os.path.join(root, name)
      root_rel_path = os.path.relpath(from_path, from_root)
      to_path = os.path.join(to_root, root_rel_path)
      to_dir = os.path.dirname(to_path)
      if not os.path.exists(to_dir):
        os.makedirs(to_dir)
      shutil.copy(from_path, to_path)

    dirs[:] = list(filter(wrapped_filter, dirs))


def remove_if_exists(path):
  try:
    os.remove(path)
  except OSError as err:
    if err.errno != errno.ENOENT:
      raise


def list_files(from_root, filter_func=None):
  file_list = []
  for root, dirs, files in os.walk(from_root):
    # filter_func expects paths not names, so wrap it to make them absolute.
    wrapped_filter = None
    if filter_func:
      wrapped_filter = lambda name, rt=root: filter_func(os.path.join(rt, name))
    for name in filter(wrapped_filter, files):
      path = os.path.join(root, name)
      file_list.append(path)
    dirs[:] = list(filter(wrapped_filter, dirs))
  return file_list


def main():
  parser = argparse.ArgumentParser(description='Generate a dart-pkg')
  parser.add_argument(
      '--dart-sdk', action='store', metavar='dart_sdk', help='Path to the Dart SDK.'
  )
  parser.add_argument(
      '--package-name',
      action='store',
      metavar='package_name',
      help='Name of package',
      required=True
  )
  parser.add_argument(
      '--pkg-directory',
      metavar='pkg_directory',
      help='Directory where dart_pkg should go',
      required=True
  )
  parser.add_argument('--stamp-file', metavar='stamp_file', help='timestamp file', required=True)
  parser.add_argument(
      '--package-sources', metavar='package_sources', help='Package sources', nargs='+'
  )
  parser.add_argument(
      '--sdk-ext-directories',
      metavar='sdk_ext_directories',
      help='Directory containing .dart sources',
      nargs='*',
      default=[]
  )
  parser.add_argument(
      '--sdk-ext-files',
      metavar='sdk_ext_files',
      help='List of .dart files that are part of sdk_ext.',
      nargs='*',
      default=[]
  )
  parser.add_argument(
      '--sdk-ext-mappings',
      metavar='sdk_ext_mappings',
      help='Mappings for SDK extension libraries.',
      nargs='*',
      default=[]
  )
  parser.add_argument(
      '--read_only',
      action='store_true',
      dest='read_only',
      help='Package is a read only package.',
      default=False
  )
  args = parser.parse_args()

  # We must have a pubspec.yaml.
  assert has_pubspec_yaml(args.package_sources)

  target_dir = os.path.join(args.pkg_directory, args.package_name)
  target_packages_dir = os.path.join(target_dir, 'packages')
  lib_path = os.path.join(target_dir, 'lib')
  ensure_dir_exists(lib_path)

  mappings = {}
  for mapping in args.sdk_ext_mappings:
    library, path = mapping.split(',', 1)
    mappings[library] = '../sdk_ext/%s' % path

  sdkext_path = os.path.join(lib_path, '_sdkext')
  if mappings:
    with open(sdkext_path, 'w') as stream:
      json.dump(mappings, stream, sort_keys=True, indent=2, separators=(',', ': '))
  else:
    remove_if_exists(sdkext_path)

  # Copy or symlink package sources into pkg directory.
  common_source_prefix = os.path.dirname(os.path.commonprefix(args.package_sources))
  for source in args.package_sources:
    relative_source = os.path.relpath(source, common_source_prefix)
    target = os.path.join(target_dir, relative_source)
    copy(source, target)

  # Copy sdk-ext sources into pkg directory
  sdk_ext_dir = os.path.join(target_dir, 'sdk_ext')
  for directory in args.sdk_ext_directories:
    sdk_ext_sources = list_files(directory, dart_filter)
    common_prefix = os.path.commonprefix(sdk_ext_sources)
    for source in sdk_ext_sources:
      relative_source = os.path.relpath(source, common_prefix)
      target = os.path.join(sdk_ext_dir, relative_source)
      copy(source, target)

  common_source_prefix = os.path.dirname(os.path.commonprefix(args.sdk_ext_files))
  for source in args.sdk_ext_files:
    relative_source = os.path.relpath(source, common_source_prefix)
    target = os.path.join(sdk_ext_dir, relative_source)
    copy(source, target)

  # Write stamp file.
  with open(args.stamp_file, 'w'):
    pass

  return 0


if __name__ == '__main__':
  sys.exit(main())
