# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys

import argparse
import errno
import os
import subprocess

def MakeDirectories(path):
    try:
        os.makedirs(path)
    except OSError as exc:
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise

def Main():
  parser = argparse.ArgumentParser()
  parser.add_argument("--output",
                    type=str, required=True,
                    help="The location to generate the Metal library to.")
  parser.add_argument("--depfile",
                    type=str, required=True,
                    help="The location of the depfile.")
  parser.add_argument("--source",
                    type=str, action="append", required=True,
                    help="The source file to compile. Can be specified multiple times.")

  args = parser.parse_args()

  MakeDirectories(os.path.dirname(args.depfile))

  command = [
    "xcrun",
    "metal",
    "-MO",
    "-gline-tables-only",
    # Both user and system header will be tracked.
    "-MMD",
    "-MF",
    args.depfile,
    "-o",
    args.output
  ]

  command += args.source

  subprocess.check_call(command)

if __name__ == '__main__':
  if sys.platform != 'darwin':
    raise Exception("This script only runs on Mac")
  Main()
