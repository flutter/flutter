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
      '--optimize',
      action='store_true',
      default=False,
      help='If available optimizations must be applied to the compiled Metal sources.'
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

  if args.platform == 'mac':
    command += [
        '-sdk',
        'macosx',
    ]
  elif args.platform == 'ios':
    command += [
        '-sdk',
        'iphoneos',
    ]
  elif args.platform == 'ios-simulator':
    command += [
        '-sdk',
        'iphonesimulator',
    ]

  command += [
      'metal',
      # These warnings are from generated code and would make no sense to the GLSL
      # author.
      '-Wno-unused-variable',
      # Both user and system header will be tracked.
      '-MMD',
      '-MF',
      args.depfile,
      '-o',
      args.output,
  ]

  # The Metal standard must match the specification in impellerc.
  if args.platform == 'mac':
    command += [
        '--std=macos-metal1.2',
    ]

  if args.optimize:
    command += [
        # Like -Os (and thus -O2), but reduces code size further.
        '-Oz',
        # Allow aggressive, lossy floating-point optimizations.
        '-ffast-math',
    ]
    if args.platform == 'ios':
      # limiting to ios-metal1.2 disables shader debug symbols, only
      # enabling these in optimize mode.
      # see https://github.com/flutter/flutter/issues/106066
      command += [
          '--std=ios-metal1.2',
          '-mios-version-min=10.0',
      ]
  else:
    command += [
        # Embeds both sources and driver options in the output. This aids in
        # debugging but should be removed from release builds.
        # TODO(chinmaygarde): Use -frecord-sources when CI upgrades to
        # Xcode 13.
        '-MO',
        # Assist the sampling profiler.
        '-gline-tables-only',
        '-g',
        # Optimize for debuggability.
        '-Og',
    ]

  command += args.source

  subprocess.check_call(command)


if __name__ == '__main__':
  if sys.platform != 'darwin':
    raise Exception('This script only runs on Mac')
  main()
