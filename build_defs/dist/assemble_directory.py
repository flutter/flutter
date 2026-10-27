#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Assembles a directory from files and directories (local_engine.bzl's `assemble`).

Each `--file <source>=<path>` is copied to <path> under the output directory;
each `--directory <source>=<path>` has its contents copied under <path>
(`.` for the output directory itself). Copies, not links: Bazel's
output-tree files are read-only and a tree artifact is one unit. A file
that is a symlink output of the build (a framework bundle's
`Versions/Current -> A`, framework.bzl: a relative target, where the
sandbox's own input links are absolute) is made again as the link it is.
"""

import argparse
import os
import shutil


def main():
  # Bazel passes the arguments in a file, one per line (@<file>).
  parser = argparse.ArgumentParser(
      description=__doc__.split('\n', maxsplit=1)[0], fromfile_prefix_chars='@'
  )
  parser.add_argument('--output', required=True)
  parser.add_argument('--file', action='append', default=[], help='<source>=<path>')
  parser.add_argument('--directory', action='append', default=[], help='<source>=<path>')
  options = parser.parse_args()

  os.makedirs(options.output, exist_ok=True)
  for entry in options.directory:
    source, path = entry.split('=', 1)
    destination = os.path.normpath(os.path.join(options.output, path))
    shutil.copytree(source, destination, dirs_exist_ok=True)
  for entry in options.file:
    source, path = entry.split('=', 1)
    destination = os.path.join(options.output, path)
    os.makedirs(os.path.dirname(destination), exist_ok=True)
    if os.path.islink(source) and not os.path.isabs(os.readlink(source)):
      if os.path.lexists(destination):
        os.remove(destination)
      os.symlink(os.readlink(source), destination)
      continue
    shutil.copyfile(source, destination)
    shutil.copymode(source, destination)


if __name__ == '__main__':
  main()
