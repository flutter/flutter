#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import shutil
import subprocess
import sys


def main():
  parser = argparse.ArgumentParser(
      description='Creates an XCFramework consisting of the specified universal frameworks'
  )

  parser.add_argument(
      '--frameworks',
      nargs='+',
      help='The framework paths used to create the XCFramework.',
      required=True
  )
  parser.add_argument(
      '--dsyms', nargs='+', help='The dSYM paths to be bundled in the XCFramework.', required=False
  )
  parser.add_argument('--name', help='Name of the XCFramework', type=str, required=True)
  parser.add_argument('--location', help='Output directory', type=str, required=True)

  args = parser.parse_args()

  create_xcframework(args.location, args.name, args.frameworks, args.dsyms)


def create_xcframework(location, name, frameworks, dsyms=None):
  if dsyms and len(frameworks) != len(dsyms):
    print('Number of --dsyms must match number of --frameworks exactly.', file=sys.stderr)
    sys.exit(1)

  output_dir = os.path.abspath(location)
  output_xcframework = os.path.join(output_dir, '%s.xcframework' % name)

  if not os.path.exists(output_dir):
    os.makedirs(output_dir)

  if os.path.exists(output_xcframework):
    # Remove old xcframework.
    shutil.rmtree(output_xcframework)

  # xcrun xcodebuild -create-xcframework -framework foo/baz.framework \
  #                  -framework bar/baz.framework -output output/
  command = ['xcrun', 'xcodebuild', '-quiet', '-create-xcframework']

  command.extend(['-output', output_xcframework])

  for i in range(len(frameworks)):  # pylint: disable=consider-using-enumerate
    command.extend(['-framework', os.path.abspath(frameworks[i])])
    if dsyms:
      command.extend(['-debug-symbols', os.path.abspath(dsyms[i])])

  subprocess.check_call(command, stdout=open(os.devnull, 'w'))


if __name__ == '__main__':
  sys.exit(main())
