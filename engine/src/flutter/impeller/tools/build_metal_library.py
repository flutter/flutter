# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys

import argparse
import errno
import os
import subprocess


def make_directories(path):
  try:
    os.makedirs(path)
  except OSError as exc:
    if exc.errno == errno.EEXIST and os.path.isdir(path):
      pass
    else:
      raise


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument(
      '--output',
      type=str,
      required=True,
      help='The location to generate the Metal library to.'
  )
  parser.add_argument(
      '--depfile', type=str, required=True, help='The location of the depfile.'
  )
  parser.add_argument(
      '--source',
      type=str,
      action='append',
      required=True,
      help='The source file to compile. Can be specified multiple times.'
  )
  parser.add_argument(
      '--platform',
      required=True,
      choices=['mac', 'ios', 'ios-simulator'],
      help='Select the platform.'
  )

  args = parser.parse_args()

  make_directories(os.path.dirname(args.depfile))

  command = [
      'xcrun',
  ]

  # Select the SDK.
  command += ['-sdk']
  if args.platform == 'mac':
    command += [
        'macosx',
    ]
  elif args.platform == 'ios':
    command += [
        'iphoneos',
    ]
  elif args.platform == 'ios-simulator':
    command += [
        'iphonesimulator',
    ]
  else:
    raise 'Unknown target platform'

  command += [
      'metal',
      # These warnings are from generated code and would make no sense to the
      # GLSL author.
      '-Wno-unused-variable',
      # Both user and system header will be tracked.
      '-MMD',
      # Like -Os (and thus -O2), but reduces code size further.
      '-Oz',
      # Allow aggressive, lossy floating-point optimizations.
      '-ffast-math',
      # Record symbols in a separate *.metallibsym file.
      '-frecord-sources=flat',
      '-MF',
      args.depfile,
      '-o',
      args.output,
  ]

  # Select the Metal standard and the minimum supported OS versions.
  # The Metal standard must match the specification in impellerc.
  if args.platform == 'mac':
    command += [
        '--std=macos-metal1.2',
        '-mmacos-version-min=10.14',
    ]
  elif args.platform == 'ios':
    command += [
        '--std=ios-metal1.2',
        '-mios-version-min=11.0',
    ]
  elif args.platform == 'ios-simulator':
    command += [
        '--std=ios-metal1.2',
        '-miphonesimulator-version-min=11.0',
    ]
  else:
    raise 'Unknown target platform'

  command += args.source

  subprocess.check_output(command, stderr=subprocess.STDOUT)


if __name__ == '__main__':
  if sys.platform != 'darwin':
    raise Exception('This script only runs on Mac')
  main()
