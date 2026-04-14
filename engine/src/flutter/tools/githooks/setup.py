#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

'''
Sets up githooks.
'''

import argparse
import os
import subprocess
import sys

SRC_ROOT = os.path.dirname(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
)
FLUTTER_DIR = os.path.join(SRC_ROOT, 'flutter')


def IsWindows():
  os_id = sys.platform
  return os_id.startswith('win32') or os_id.startswith('cygwin')


def Main(argv):
  parser = argparse.ArgumentParser()

  parser.add_argument('--unset', action=argparse.BooleanOptionalAction, default=False)

  args = parser.parse_args()

  git = 'git'
  if IsWindows():
    git = 'git.bat'

  command = [
      git,
      'config',
  ]

  if args.unset:
    command += [
        '--unset',
        'core.hooksPath',
    ]
    print('Uninstalling Git Hooks')
  else:
    githooks = os.path.join(FLUTTER_DIR, 'tools', 'githooks')
    command += [
        'core.hooksPath',
        githooks,
    ]
    print('Installing Git Hooks')

  result = subprocess.run(command, cwd=FLUTTER_DIR)
  return result.returncode


if __name__ == '__main__':
  sys.exit(Main(sys.argv))
