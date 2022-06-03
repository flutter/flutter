#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

""" Compiles a cml manifest file.
"""

import argparse
import os
import subprocess
import sys


def main():
  parser = argparse.ArgumentParser()

  parser.add_argument(
      '--cmc-bin', dest='cmc_bin', action='store', required=True
  )
  parser.add_argument('--output', dest='output', action='store', required=True)
  parser.add_argument(
      '--manifest-file', dest='manifest_file', action='store', required=True
  )
  parser.add_argument(
      '--includepath',
      dest='includepath',
      action='append',
      required=True,
  )

  args = parser.parse_args()

  assert os.path.exists(args.cmc_bin)
  assert os.path.exists(args.manifest_file)

  subprocess.check_output([
      args.cmc_bin,
      'compile',
      '--output',
      args.output,
      args.manifest_file,
  ] + (args.includepath and ['--includepath'] + args.includepath))

  return 0


if __name__ == '__main__':
  sys.exit(main())
