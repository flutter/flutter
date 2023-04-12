#!/usr/bin/env vpython3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import subprocess
import sys

SRC_ROOT = os.path.dirname(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
)


def parse_args(argv):
  parser = argparse.ArgumentParser(
      description='A script that tests the impeller-cmake-example build.',
  )
  parser.add_argument(
      '--build',
      '-b',
      default=False,
      action='store_true',
      help='Perform the build for impeller-cmake-example.',
  )
  parser.add_argument(
      '--cmake',
      '-c',
      default=False,
      action='store_true',
      help='Run cmake for impeller-cmake-example.',
  )
  parser.add_argument(
      '--goma-dir',
      '-g',
      type=str,
      default=os.getenv('GOMA_DIR'),
      help=(
          'The path to the Goma install. Defaults to the value of the '
          'GOMA_DIR environment variable.'
      ),
  )
  parser.add_argument(
      '--path',
      '-p',
      type=str,
      help='The path to the impeller-cmake-example source.',
  )
  parser.add_argument(
      '--setup',
      '-s',
      default=False,
      action='store_true',
      help='Clone the git submodules.',
  )
  parser.add_argument(
      '--verbose',
      '-v',
      default=False,
      action='store_true',
      help='Emit verbose output.',
  )
  parser.add_argument(
      '--xcode-symlink',
      default=False,
      action='store_true',
      help='Symlink the Xcode sysroot to help Goma be successful.',
  )
  return parser.parse_args(argv)


def validate_args(args):
  if not os.path.isdir(os.path.join(SRC_ROOT, args.path)):
    print(
        'The --path argument must be a valid directory relative to the '
        'engine src/ directory.'
    )
    return False

  return True


def create_xcode_symlink():
  find_sdk_command = [
      'python3',
      os.path.join(SRC_ROOT, 'build', 'mac', 'find_sdk.py'),
      '--print_sdk_path',
      '10.15',
      '--symlink',
      os.path.join(SRC_ROOT, 'out', 'impeller-cmake-example-xcode-sysroot'),
  ]
  find_sdk_output = subprocess.check_output(find_sdk_command).decode('utf-8')
  print(find_sdk_output)
  sysroot_path = find_sdk_output.split('\n')[0]
  print('sysroot path = {}'.format(sysroot_path))
  return sysroot_path


def main(argv):
  args = parse_args(argv[1:])
  if not validate_args(args):
    return 1

  impeller_cmake_dir = os.path.join(SRC_ROOT, args.path)

  if args.setup:
    print('git submodule update with {} jobs'.format(str(os.cpu_count())))
    git_command = [
        'git',
        '-C',
        impeller_cmake_dir,
        'submodule',
        'update',
        '--init',
        '--recursive',
        # '--single-branch',
        '--depth',
        '1',
        '--jobs',
        str(os.cpu_count()),
    ]
    subprocess.check_call(git_command)

    # Run the deps.sh shell script in the repo.
    subprocess.check_call(['bash', 'deps.sh'], cwd=impeller_cmake_dir)
    return 0

  if args.cmake:
    cmake_command = [
        'cmake',
        '--preset',
        'flutter-ci-mac-debug-x64',
        '-B',
        os.path.join(SRC_ROOT, 'out', 'impeller-cmake-example-out'),
    ]
    cmake_env = os.environ.copy()
    cmake_env.update({
        'FLUTTER_ENGINE_SRC_DIR': SRC_ROOT,
        'FLUTTER_GOMA_DIR': args.goma_dir,
    })
    if args.xcode_symlink:
      xcode_symlink_path = create_xcode_symlink()
      cmake_env.update({
          'FLUTTER_OSX_SYSROOT': xcode_symlink_path,
      })
    subprocess.check_call(cmake_command, env=cmake_env, cwd=impeller_cmake_dir)

  if args.build:
    ninja_command = [
        'ninja',
        '-C',
        os.path.join(SRC_ROOT, 'out', 'impeller-cmake-example-out'),
        '-j',
        '200',
    ]
    subprocess.check_call(ninja_command)

  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
