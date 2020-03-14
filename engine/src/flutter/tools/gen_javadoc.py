#!/usr/bin/env python
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import subprocess
import sys

ANDROID_SRC_ROOT = 'flutter/shell/platform/android'


def main():
  parser = argparse.ArgumentParser(description='Runs javadoc on Flutter Android libraries')
  parser.add_argument('--out-dir', type=str, required=True)
  parser.add_argument('--android-source-root', type=str, default=ANDROID_SRC_ROOT)
  parser.add_argument('--build-config-path', type=str)
  parser.add_argument('--third-party', type=str, default='third_party')
  args = parser.parse_args()

  if not os.path.exists(args.android_source_root):
    print('This script must be run at the root of the Flutter source tree, or '
          'the --android-source-root must be set.')
    return 1

  if not os.path.exists(args.out_dir):
    os.makedirs(args.out_dir)

  classpath = [
    args.android_source_root,
    os.path.join(args.third_party, 'android_embedding_dependencies', 'lib', '*'),
  ]
  if args.build_config_path:
    classpath.append(args.build_config_path)

  packages = [
    'io.flutter.app',
    'io.flutter.embedding.android',
    'io.flutter.embedding.engine',
    'io.flutter.embedding.engine.dart',
    'io.flutter.embedding.engine.loader',
    'io.flutter.embedding.engine.plugins',
    'io.flutter.embedding.engine.plugins.activity',
    'io.flutter.embedding.engine.plugins.broadcastreceiver',
    'io.flutter.embedding.engine.plugins.contentprovider',
    'io.flutter.embedding.engine.plugins.lifecycle',
    'io.flutter.embedding.engine.plugins.service',
    'io.flutter.embedding.engine.plugins.shim',
    'io.flutter.embedding.engine.renderer',
    'io.flutter.embedding.engine.systemchannels',
    'io.flutter.plugin.common',
    'io.flutter.plugin.editing',
    'io.flutter.plugin.platform',
    'io.flutter.util',
    'io.flutter.view',
  ]

  command = [
    'javadoc',
    '-classpath', ':'.join(classpath),
    '-d', args.out_dir,
    '-link', 'https://developer.android.com/reference/',
  ] + packages
  print(' '.join(command))

  return subprocess.call(command)


if __name__ == '__main__':
  sys.exit(main())
