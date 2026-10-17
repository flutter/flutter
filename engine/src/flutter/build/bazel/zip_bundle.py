#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Runs build/zip.py over the files a Bazel zip_bundle's entries name (zip_bundle.bzl).

zip.py stores a symlink as a symlink entry (a macOS framework's), and every
input of a sandboxed action is a symlink, where GN hands the script its build
directory's real files. Each `-i` source is resolved to the file it names
before zip.py sees it; everything else is zip.py's own command line.

Usage: zip_bundle.py <zip.py> -o <output> -i <source> <destination>...
"""

import os
import runpy
import sys


def main(argv):
  script = argv[1]
  args = argv[2:]
  for i, arg in enumerate(args):
    if arg == '-i' and i + 1 < len(args):
      args[i + 1] = os.path.realpath(args[i + 1])
  sys.argv = [script] + args
  runpy.run_path(script, run_name='__main__')


if __name__ == '__main__':
  main(sys.argv)
