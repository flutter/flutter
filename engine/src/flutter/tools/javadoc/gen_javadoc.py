#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import subprocess
import sys

ANDROID_SRC_ROOT = 'flutter/shell/platform/android'

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))


def JavadocBin():
  if sys.platform == 'darwin':
    return os.path.join(
        SCRIPT_DIR, '..', '..', 'third_party', 'java', 'openjdk', 'Contents', 'Home', 'bin',
        'javadoc'
    )
  elif sys.platform.startswith(('cygwin', 'win')):
    return os.path.join(
        SCRIPT_DIR, '..', '..', 'third_party', 'java', 'openjdk', 'bin', 'javadoc.exe'
    )
  else:
    return os.path.join(SCRIPT_DIR, '..', '..', 'third_party', 'java', 'openjdk', 'bin', 'javadoc')


def main():
  parser = argparse.ArgumentParser(description='Runs javadoc on Flutter Android libraries')
  parser.add_argument('--out-dir', type=str, required=True)
  parser.add_argument('--android-source-root', type=str, default=ANDROID_SRC_ROOT)
  parser.add_argument('--build-config-path', type=str)
  parser.add_argument('--src-dir', type=str, default='.')
  parser.add_argument('--quiet', default=False, action='store_true')
  # The inputs the script otherwise finds by their paths in the source tree,
  # for a build that lays them elsewhere (the Bazel build's sandbox).
  parser.add_argument(
      '--javadoc-bin',
      type=str,
      default=None,
      help='The javadoc binary; the checkout\'s JDK by default.'
  )
  parser.add_argument(
      '--android-jar',
      type=str,
      default=None,
      help='The Android SDK\'s android.jar; the checkout\'s by default.'
  )
  parser.add_argument(
      '--embedding-dependencies-dir',
      type=str,
      default=None,
      help='The directory of the embedding\'s dependency jars; the checkout\'s by default.'
  )
  args = parser.parse_args()

  if not os.path.exists(args.android_source_root):
    print(
        'This script must be run at the root of the Flutter source tree, or '
        'the --android-source-root must be set.'
    )
    return 1

  if not os.path.exists(args.out_dir):
    os.makedirs(args.out_dir)

  android_jar_path = args.android_jar or os.path.join(
      args.src_dir, 'flutter', 'third_party', 'android_tools', 'sdk', 'platforms', 'android-37.0',
      'android.jar'
  )
  if not os.path.exists(android_jar_path):
    print('Android SDK not found at %s' % android_jar_path)
    return 1

  embedding_dependencies_dir = args.embedding_dependencies_dir or os.path.join(
      args.src_dir, 'flutter', 'third_party', 'android_embedding_dependencies', 'lib'
  )

  classpath = [
      args.android_source_root,
      os.path.join(args.android_source_root, 'debug'),
      os.path.join(args.android_source_root, 'release'),
      android_jar_path,
      os.path.join(embedding_dependencies_dir, '*'),
  ]
  if args.build_config_path:
    classpath.append(args.build_config_path)

  packages = [
      'io.flutter.app',
      'io.flutter.embedding.android',
      'io.flutter.embedding.engine',
      'io.flutter.embedding.engine.dart',
      'io.flutter.embedding.engine.flags',
      'io.flutter.embedding.engine.loader',
      'io.flutter.embedding.engine.mutatorsstack',
      'io.flutter.embedding.engine.plugins',
      'io.flutter.embedding.engine.plugins.activity',
      'io.flutter.embedding.engine.plugins.broadcastreceiver',
      'io.flutter.embedding.engine.plugins.contentprovider',
      'io.flutter.embedding.engine.plugins.lifecycle',
      'io.flutter.embedding.engine.plugins.service',
      'io.flutter.embedding.engine.renderer',
      'io.flutter.embedding.engine.systemchannels',
      'io.flutter.plugin.common',
      'io.flutter.plugin.editing',
      'io.flutter.plugin.platform',
      'io.flutter.util',
      'io.flutter.view',
  ]

  android_package_list = os.path.join(SCRIPT_DIR, 'android_reference')

  command = [
      args.javadoc_bin or JavadocBin(),
      '-classpath',
      ':'.join(classpath),
      '-d',
      args.out_dir,
      '-linkoffline',
      'https://developer.android.com/reference/',
      android_package_list,
      '-source',
      '1.8',
  ] + packages

  if not args.quiet:
    print(' '.join(command))

  try:
    output = subprocess.check_output(command, stderr=subprocess.STDOUT)
    if not args.quiet:
      print(output)
  except subprocess.CalledProcessError as e:
    print(e.output.decode('utf-8'))
    return e.returncode

  return 0


if __name__ == '__main__':
  sys.exit(main())
