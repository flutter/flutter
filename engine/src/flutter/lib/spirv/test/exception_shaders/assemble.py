#!/usr/bin/env python
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import subprocess

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument(
      'input',
      type=pathlib.Path,
      required=True,
      help='path to input SPIR-V assembly file')
  parser.add_argument(
      'output',
      type=pathlib.Path,
      required=True,
      help='path to output SPIR-V binary file')
  args = parser.parse_args()
  subprocess.run([
    'spirv-as',
    '-o',
    args.output,
    args.input,
  ])

if __name__ == '__main__':
  main()
