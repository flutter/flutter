#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import subprocess
import sys


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('--cxxbridge', required=True)
  parser.add_argument('--input', required=True)
  parser.add_argument('--header', required=True)
  parser.add_argument('--cc', required=True)
  args = parser.parse_args()

  cxxbridge = os.path.abspath(args.cxxbridge)
  subprocess.run(
      [cxxbridge, args.input, '--header', '-o', args.header], check=True
  )
  subprocess.run([cxxbridge, args.input, '-o', args.cc], check=True)
  return 0


if __name__ == '__main__':
  sys.exit(main())
