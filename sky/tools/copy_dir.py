#!/usr/bin/env python
# Copyright 2016 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import subprocess
import shutil
import sys
import os


def MakeStamp(stamp_path):
  dir_name = os.path.dirname(stamp_path)

  if not os.path.isdir(dir_name):
    os.makedirs()

  with open(stamp_path, 'a'):
    os.utime(stamp_path, None)


def main():
  parser = argparse.ArgumentParser(description='Copy a directory')

  parser.add_argument('--src', type=str)
  parser.add_argument('--dst', type=str)
  parser.add_argument('--stamp', type=str)

  args = parser.parse_args()

  shutil.rmtree(args.dst, True)
  shutil.copytree(args.src, args.dst)

  MakeStamp(args.stamp)


if __name__ == '__main__':
  sys.exit(main())
