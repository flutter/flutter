#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import subprocess
import sys


def main():
  parser = argparse.ArgumentParser(
      description='Copies an input macOS binary to the specified output path. '
      'Bitcode segments, if any, are stripped.'
  )
  parser.add_argument(
      '--input',
      type=str,
      required=True,
      help='path of input binary to be read'
  )
  parser.add_argument(
      '--output',
      type=str,
      required=True,
      help='path of output binary to be written'
  )
  args = parser.parse_args()

  # Verify input binary exists.
  if not os.path.isfile(args.input):
    print('Cannot find input binary at %s' % args.input)
    sys.exit(1)

  # Copy input path to output path. Strip bitcode segments, if any.
  subprocess.check_call([
      'xcrun', 'bitcode_strip', '-r', args.input, '-o', args.output
  ])


if __name__ == '__main__':
  sys.exit(main())
