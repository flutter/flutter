#!/usr/bin/env python
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import subprocess
import sys

# BFD architecture names recognized by objcopy.
BFD_ARCH = {
  'arm': 'arm',
  'arm64': 'aarch64',
  'x86': 'i386',
  'x64': 'i386:x86-64',
}

# BFD target names recognized by objcopy.
BFD_TARGET = {
  'arm': 'elf32-littlearm',
  'arm64': 'elf64-littleaarch64',
  'x86': 'elf32-i386',
  'x64': 'elf64-x86-64',
}

def main():
  parser = argparse.ArgumentParser(description='Convert a data file to an object file')
  parser.add_argument('--objcopy', type=str, required=True)
  parser.add_argument('--input', type=str, required=True)
  parser.add_argument('--output', type=str, required=True)
  parser.add_argument('--arch', type=str, required=True)

  args = parser.parse_args()

  input_dir, input_file = os.path.split(args.input)
  output_path = os.path.abspath(args.output)

  subprocess.check_call([
    args.objcopy,
    '-I', 'binary',
    '-O', BFD_TARGET[args.arch],
    '-B', BFD_ARCH[args.arch],
    input_file,
    output_path,
  ], cwd=input_dir)

if __name__ == '__main__':
  sys.exit(main())
